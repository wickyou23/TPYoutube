//
//  AWTPWCSessionHandler.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 05/04/2023.
//

import Foundation
import SwiftUI

class AWTPWCSessionHandler {
    private let playerManager = AWTPPlayerManager.shared
    private let wcCommand = AWTPWCSessionCommands()
    
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
        case .playControl:
            playerManager.setPlayerState(newState: .playing)
        case .pauseControl:
            playerManager.setPlayerState(newState: .paused)
        case .backControl, .nextControl, .loadVideo:
            guard let metadata = rawCommand.metadata,
                  let newVideo = try? jsDecoder.decode(TPYTVideo.self, from: metadata) else {
                return
            }
            
            playerManager.setNewVideo(newVideo: newVideo)
        case .averageColorOfCurrentVideo:
            guard let metadata = rawCommand.jsonMetadata,
                  let hexColor = metadata[kColor] as? UInt else {
                return
            }
            
            let color = Color(cgColor: CGColor.initWithHex(hex: hexColor))
            playerManager.setAverageColorOfCurrentVideo(color: color)
        case .closePlayer:
            playerManager.closePlayer()
        case .playerTime:
            guard let metadata = rawCommand.jsonMetadata,
                  let time = metadata[kTime] as? Float,
                  let duration = metadata[kDuration] as? Float else {
                return
            }
            
            playerManager.setNewTime(time: TPPlayerTime(time: time, duration: duration))
        case .parentAppDidEnterBackground:
            playerManager.getCurrentVideoIsPlaying()
        default:
            return
        }
    }
}
