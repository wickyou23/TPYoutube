//
//  TPWCSessionHandler.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation

class TPWCSessionHandler {
    lazy var jsEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        return encoder
    }()
    
    lazy var jsDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        return decoder
    }()
    
    private let player = TPYTPlayerManager.shared
    
    func handleCommandRecived(command: Any, replyHandler: @escaping ([String : Any]) -> Void) {
        var rawCommand: TPCommand?
        if let command = command as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: command) {
            rawCommand = try? jsDecoder.decode(TPCommand.self, from: jsonData)
        }
        else if let command = command as? TPCommand {
            rawCommand = command
        }
        
        guard let rawCommand = rawCommand else {
            fatalError("Command not support")
        }
        
        switch rawCommand.command {
        case .getSearchingVideo:
            guard let dataResponse = getSearchingVideo() else {
                return
            }
            
            let command = TPCommand(command: .getSearchingVideo, phrase: .replied, metadata: dataResponse)
            replyHandler(command.toJson() ?? [:])
        case .loadVideo:
            guard let videoId = rawCommand.jsonMetadata?[kVideoID] as? String else {
                return
            }
            
            let isPlayed = playVideo(videoId: videoId)
            let command = TPCommand(command: .loadVideo, phrase: .replied, metadata: [kIsPlayed: isPlayed])
            replyHandler(command.toJson() ?? [:])
        case .playControl:
            playControl()
            let command = TPCommand(command: .playControl, phrase: .replied)
            replyHandler(command.toJson() ?? [:])
        case .pauseControl:
            pauseControl()
            let command = TPCommand(command: .pauseControl, phrase: .replied)
            replyHandler(command.toJson() ?? [:])
        case .nextControl:
            guard let nextVideo = nextControl(),
                  let data = try? jsEncoder.encode(nextVideo) else {
                return
            }
            
            let command = TPCommand(command: .nextControl, phrase: .replied, metadata: data)
            replyHandler(command.toJson() ?? [:])
        case .backControl:
            guard let backVideo = backControl(),
                  let data = try? jsEncoder.encode(backVideo) else {
                return
            }
            
            let command = TPCommand(command: .backControl, phrase: .replied, metadata: data)
            replyHandler(command.toJson() ?? [:])
        case .playerTime:
            let time = player.playertime
            let command = TPCommand(command: .playerTime, phrase: .replied, metadata: [kTime: time.time, kDuration: time.duration])
            replyHandler(command.toJson() ?? [:])
        case .currentVideoIsPlaying:
            Task {
                var command: TPCommand!
                if let nextVideo = getCurrentVideoIsPlaying(),
                   let videoData = try? jsEncoder.encode(nextVideo),
                    let jsVideo = try? JSONSerialization.jsonObject(with: videoData) as? [String: Any] {
                    let metadata: [String: Any] = [kVideoData: jsVideo,
                                                 kPlayerState: player.state.rawValue,
                                                        kTime: player.playertime.time,
                                                    kDuration: player.playertime.duration,
                                                       kColor: await player.getGradientColorsFromImage().first!.cgColor!.toInt()]
                    command = TPCommand(command: .nextControl, phrase: .replied, metadata: metadata)
                }
                else {
                    command = TPCommand(command: .nextControl, phrase: .replied)
                }
                
                replyHandler(command.toJson() ?? [:])
            }
        default:
            return
        }
    }
    
    private func getSearchingVideo() -> Data? {
        guard let cachingData = TPStorageManager.yt.getSearchingVideoPage(type: Data.self) else {
            return nil
        }
        
        return cachingData
    }
    
    private func playVideo(videoId: String) -> Bool {
        if !player.isPlaying && player.currentVideo?.id == videoId {
            player.play()
            return true
        }
        
        let searchingVideos = TPStorageManager.yt.getSearchingVideoPage()?.items ?? []
        if let first = searchingVideos.first(where: { $0.id == videoId }) {
            player.load(video: first, playlist: searchingVideos)
            return true
        }
        else {
            return false
        }
    }
    
    private func pauseControl() {
        player.pause()
    }
    
    private func playControl() {
        player.play()
    }
    
    private func nextControl() -> TPYTItemResource? {
        return player.nextSong()
    }
    
    private func backControl() -> TPYTItemResource? {
        return player.backSong()
    }
    
    private func getCurrentVideoIsPlaying() -> TPYTItemResource? {
        return player.currentVideo
    }
}
