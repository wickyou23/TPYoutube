//
//  TPYTServices.swift
//  TPYoutube
//
//  Created by Thang Phung on 23/02/2023.
//

import Foundation
import Moya
import CombineMoya
import Combine

protocol ITPYTServices {
    func searchVideos(by text: String) -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError>
    func getPlaylist() -> AnyPublisher<TPYTPaging<TPYTPlaylist>, MoyaError>
    func getLikedVideos() -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError>
    func getMostPopularVideos(regionCode: String) -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError>
    func getVideosByPlaylist(playlist: TPYTPlaylist) -> AnyPublisher<TPYTPaging<TPYTPlaylistItem>, MoyaError>
    func getVideoV1(videoId: String) -> AnyPublisher<TPYTVideoV1, MoyaError>
    func getStreammingAudioURL(m3u8URL: String) -> AnyPublisher<[Int: String], Moya.MoyaError>
}

enum TPYTVideoType {
    case likedVideos, mostPopular, playListVideos(playList: TPYTPlaylist), historyVideo
    
    var title: String {
        switch self {
        case .likedVideos:
            return "Liked Videos"
        case .mostPopular:
            return "Trending Videos"
        case .historyVideo:
            return "History Videos"
        case .playListVideos(let playList):
            return playList.snippet.title
        }
    }
}

struct TPYTServicesImp: ITPYTServices {
    private let provider: TPGGMoyaProvider<TPYTServiceTarget>
    private let youtubeV1Session: URLSession
    
    var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        return decoder
    }
    
    init() {
        provider = .init(plugins: [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(logOptions: NetworkLoggerPlugin.Configuration.LogOptions.verbose))])
        
        let urlSessionConfig = URLSessionConfiguration.ephemeral
        let cookieValue = "f1=50000000&f6=8&hl=en"
        let additionalCookie = HTTPCookie(properties: [
            .path: "/",
            .name: "PREF",
            .value: cookieValue,
            .domain: ".youtube.com",
            .secure: true
        ])
        
        urlSessionConfig.httpCookieStorage?.setCookie(additionalCookie!)
        urlSessionConfig.headers = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15"
        ]
        
        youtubeV1Session = URLSession(configuration: urlSessionConfig)
    }
    
    func searchVideos(by text: String) -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError> {
        return provider.requestGGPublisher(.search(q: text))
            .map({ $0.data })
            .decode(type: TPYTPaging<TPYTVideo>.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    func getPlaylist() -> AnyPublisher<TPYTPaging<TPYTPlaylist>, MoyaError> {
        return provider.requestGGPublisher(.getPlaylist)
            .map({ $0.data })
            .decode(type: TPYTPaging<TPYTPlaylist>.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    func getLikedVideos() -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError> {
        return provider.requestGGPublisher(.getLikedVideos)
            .map({ $0.data })
            .decode(type: TPYTPaging<TPYTVideo>.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    
    func getMostPopularVideos(regionCode: String) -> AnyPublisher<TPYTPaging<TPYTVideo>, MoyaError> {
        return provider.requestGGPublisher(.getMostPopularVideos(regionCode: regionCode))
            .map({ $0.data })
            .decode(type: TPYTPaging<TPYTVideo>.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    func getVideosByPlaylist(playlist: TPYTPlaylist) -> AnyPublisher<TPYTPaging<TPYTPlaylistItem>, MoyaError> {
        return provider.requestGGPublisher(.getVideosByPlaylist(playlistId: playlist.playlistId))
            .map({ $0.data })
            .decode(type: TPYTPaging<TPYTPlaylistItem>.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    func getVideoV1(videoId: String) -> AnyPublisher<TPYTVideoV1, Moya.MoyaError> {
        let v1Target = TPYTServiceTarget.getVideoV1(videoId: videoId)
        var urlComponents = URLComponents(string: v1Target.baseURL.absoluteString + v1Target.path)
        guard case let .requestCompositeData(bodyData: httpBody, urlParameters: urlParams) = v1Target.task else {
            return Fail(error: MoyaError.requestMapping("Repuest data error"))
                .eraseToAnyPublisher()
        }
        
        urlComponents?.queryItems = urlParams.map({ URLQueryItem(name: $0.key, value: $0.value as? String) })

        var urlRequest = URLRequest(url: urlComponents!.url!)
        urlRequest.method = v1Target.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = httpBody
        return youtubeV1Session.dataTaskPublisher(for: urlRequest)
            .map {
                if let jsonString = String(data: $0.data, encoding: .utf8) {
                    sLog("[VIDEO_V1] \(jsonString)")
                }
                
                return $0.data
            }
            .decode(type: TPYTVideoV1.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
    
    func getStreammingAudioURL(m3u8URL: String) -> AnyPublisher<[Int: String], Moya.MoyaError> {
        return provider.requestGGPublisher(.downloadm3u8File(url: m3u8URL))
            .tryMap({ reponse in
                guard reponse.statusCode == 200 else {
                    throw MoyaError.statusCode(reponse)
                }
                
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: TPYTServiceTarget.tempoM3U8URL.path()) else {
                    throw MoyaError.jsonMapping(reponse)
                }
                
                let m3u8Content = try String(contentsOf: TPYTServiceTarget.tempoM3U8URL)
                let m3u8Lines = m3u8Content.components(separatedBy: "\n")
                var streamingAudioUrls: [Int: String] = [:]
                for line in m3u8Lines {
                    guard line.hasPrefix("#EXT-X-MEDIA:URI") else {
                        continue
                    }
                    
                    let groupId = line.components(separatedBy: "GROUP-ID=")
                    let regex = try Regex("#EXT-X-MEDIA:URI=\\\"(.+?)\\\"")
                    if groupId[1].hasPrefix("\"233\"") {
                        if let regexMatch = groupId[0].firstMatch(of: regex),
                           let group1MatchRange = regexMatch[1].range {
                            streamingAudioUrls[233] = String(groupId[0][group1MatchRange])
                        }
                    }
                    
                    if groupId[1].hasPrefix("\"234\"") {
                        if let regexMatch = groupId[0].firstMatch(of: regex),
                           let group1MatchRange = regexMatch[1].range {
                            streamingAudioUrls[234] = String(groupId[0][group1MatchRange])
                        }
                    }
                }
                
                return streamingAudioUrls
            })
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
}

