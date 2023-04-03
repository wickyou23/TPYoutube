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
        case .playVideo:
            guard let videoId = rawCommand.jsonMetadata?["videoId"] as? String else {
                return
            }
            
            let isPlayed = playVideo(videoId: videoId)
            let command = TPCommand(command: .playVideo, phrase: .replied, metadata: ["isPlayed": isPlayed])
            replyHandler(command.toJson() ?? [:])
        case .pauseVideo:
            pauseVideo()
            let command = TPCommand(command: .pauseVideo, phrase: .replied)
            replyHandler(command.toJson() ?? [:])
        case .nextVideo:
            guard let nextVideo = nextVideo(),
                  let data = try? jsEncoder.encode(nextVideo) else {
                return
            }
            
            let command = TPCommand(command: .nextVideo, phrase: .replied, metadata: data)
            replyHandler(command.toJson() ?? [:])
        case .backVideo:
            guard let backVideo = backVideo(),
                  let data = try? jsEncoder.encode(backVideo) else {
                return
            }
            
            let command = TPCommand(command: .backVideo, phrase: .replied, metadata: data)
            replyHandler(command.toJson() ?? [:])
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
        let playerManager = TPYTPlayerManager.shared
        if !playerManager.isPlaying && playerManager.currentVideo?.id == videoId {
            playerManager.play()
            return true
        }
        
        let searchingVideos = TPStorageManager.yt.getSearchingVideoPage()?.items ?? []
        if let first = searchingVideos.first(where: { $0.id == videoId }) {
            playerManager.load(video: first, playlist: searchingVideos)
            return true
        }
        else {
            return false
        }
    }
    
    private func pauseVideo() {
        TPYTPlayerManager.shared.pause()
    }
    
    private func nextVideo() -> TPYTItemResource? {
        return TPYTPlayerManager.shared.nextSong()
    }
    
    private func backVideo() -> TPYTItemResource? {
        return TPYTPlayerManager.shared.backSong()
    }
}
