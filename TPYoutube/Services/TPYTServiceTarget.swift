//
//  TPYTServices.swift
//  TPYoutube
//
//  Created by Thang Phung on 23/02/2023.
//

import Foundation
import Moya

enum TPYTServiceTarget {
    case search(q: String)
    case getPlaylist
    case getLikedVideos
    case getMostPopularVideos(regionCode: String)
    case getVideosByPlaylist(playlistId: String)
    case getVideoV1(videoId: String)
}

extension TPYTServiceTarget: ITPGGServiceTargetType {
    var baseURL: URL {
        switch self {
        case .getVideoV1(_):
            return URL(string: "https://youtubei.googleapis.com/youtubei/v1")!
        default:
            return URL(string: "https://youtube.googleapis.com/youtube/v3")!
        }
    }
    
    var path: String {
        switch self {
        case .search(_):
            return "/search"
        case .getPlaylist:
            return "/playlists"
        case .getLikedVideos, .getMostPopularVideos(_):
            return "/videos"
        case .getVideosByPlaylist(_):
            return "/playlistItems"
        case .getVideoV1(_):
            return "/player"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .search(_), .getPlaylist, .getLikedVideos,
                .getMostPopularVideos(_),
                .getVideosByPlaylist(_):
            return .get
        case .getVideoV1(_):
            return .post
        }
    }
    
    var task: Moya.Task {
        let kGGAPIKey = AppViewModel.appKeys.youtubeAPIKey
        let kInnertubeApiKey = AppViewModel.appKeys.innerYoutubeAPIKey
        switch self {
        case .search(let q):
            let params: [String: Any] = ["key": kGGAPIKey,
                                         "q": q,
                                         "part": "snippet,id",
                                         "maxResults": 50,
                                         "type": "video"]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getPlaylist:
            let params: [String: Any] = ["key": kGGAPIKey,
                                         "part": "id,snippet,contentDetails,player,status",
                                         "maxResults": 50,
                                         "mine": true]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getLikedVideos:
            let params: [String: Any] = ["key": kGGAPIKey,
                                         "part": "id,snippet,contentDetails,statistics",
                                         "maxResults": 50,
                                         "myRating": "like"]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getMostPopularVideos(let regionCode):
            let params: [String: Any] = ["key": kGGAPIKey,
                                         "part": "id,snippet,contentDetails,statistics",
                                         "maxResults": 50,
                                         "chart": "mostPopular",
                                         "regionCode": regionCode]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getVideosByPlaylist(let playlistId):
            let params: [String: Any] = ["key": kGGAPIKey,
                                         "part": "id,snippet,contentDetails,status",
                                         "maxResults": 50,
                                         "playlistId": playlistId]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getVideoV1(let videoId):
            let params: [String: Any] = ["key": kInnertubeApiKey]
            let bodyParams: [String: Any] = [
                "context": [
                    "client": [
                        "clientName": "IOS",
                        "clientVersion": "17.36.4",
                        "clientScreen": "WATCH"
                    ]
                ],
                "videoId": "\(videoId)",
                "racyCheckOk": true,
                "contentCheckOk": true
            ]
            
            return .requestCompositeData(bodyData: try! JSONSerialization.data(withJSONObject: bodyParams, options: .prettyPrinted),
                                         urlParameters: params)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .getPlaylist,
                .getLikedVideos,
                .getVideosByPlaylist(_):
            var customHeader = ["Accept": "application/json"]
            if let ytAuth = TPGGAuthManager.shared.authorization,
               let accessToken = ytAuth.authState.lastTokenResponse?.accessToken {
                customHeader["Authorization"] = "Bearer \(accessToken)"
            }
            
            return customHeader
        case .getVideoV1(_):
            return ["Content-Type": "application/json"]
        default:
            return nil
        }
    }
}
