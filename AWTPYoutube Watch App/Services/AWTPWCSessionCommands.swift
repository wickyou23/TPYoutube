//
//  AWTPWCSessionCommands.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import WatchConnectivity
import SwiftUI

enum AWTPWCSessionCommandsError: Error {
    case videoNotFound
}

struct AWTPWCSessionCommands {
    private let jsEncoder: JSONEncoder
    private let jsDecoder: JSONDecoder
    
    init() {
        self.jsEncoder = JSONEncoder()
        self.jsEncoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        
        self.jsDecoder = JSONDecoder()
        self.jsDecoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
    }
    
    func getSearchingVideos(completion: @escaping (TPYTPaging<TPYTVideo>?, Error?) -> Void) {
        let command = TPCommand(command: .getSearchingVideo, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            guard let repliedCommand = TPCommand.initWithJson(json: replyMessage),
                  let metadata = repliedCommand.metadata else {
                return
            }
            
            do {
                let responseData = try self.jsDecoder.decode(TPYTPaging<TPYTVideo>.self, from: metadata)
                DispatchQueue.main.async {
                    completion(responseData, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        })
    }
    
    func loadVideo(at video: TPYTItemResource, completion: @escaping (Bool, Error?) -> Void) {
        let command = TPCommand(command: .loadVideo, phrase: .sent, metadata: [kVideoID: video.id])
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            guard let repliedCommand = TPCommand.initWithJson(json: replyMessage),
                  let jsonMetadata = repliedCommand.jsonMetadata else {
                return
            }
            
            DispatchQueue.main.async {
                completion(jsonMetadata[kIsPlayed] as! Bool, nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func playControl(completion: @escaping (Bool, Error?) -> Void) {
        let command = TPCommand(command: .playControl, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func pauseControl(completion: @escaping (Bool, Error?) -> Void) {
        let command = TPCommand(command: .pauseControl, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func nextControl(completion: @escaping (TPYTItemResource?, Error?) -> Void) {
        let command = TPCommand(command: .nextControl, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            handleVideoReponse(replyMessage: replyMessage, completion: completion)
        }) { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    func backControl(completion: @escaping (TPYTItemResource?, Error?) -> Void) {
        let command = TPCommand(command: .nextControl, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            handleVideoReponse(replyMessage: replyMessage, completion: completion)
        }) { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    func getPlayerTime(completion: @escaping (TPPlayerTime?, Error?) -> Void) {
        let command = TPCommand(command: .playerTime, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            guard let repliedCommand = TPCommand.initWithJson(json: replyMessage),
                  let jsonMetadata = repliedCommand.jsonMetadata else {
                return
            }
            
            DispatchQueue.main.async {
                completion(TPPlayerTime(time: jsonMetadata[kTime] as! Float, duration: jsonMetadata[kDuration] as! Float), nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    func getCurrentVideoIsPlaying(completion: @escaping (TPYTItemResource?, TPPlayerState, TPPlayerTime, Color?, Error?) -> Void) {
        let command = TPCommand(command: .currentVideoIsPlaying, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            handleGettingCurrentVideoReponse(replyMessage: replyMessage, completion: completion)
        }) { error in
            DispatchQueue.main.async {
                completion(nil, .unknown, .zero, nil, error)
            }
        }
    }
    
    private func handleVideoReponse(replyMessage: [String: Any], completion: @escaping (TPYTItemResource?, Error?) -> Void) {
        guard let repliedCommand = TPCommand.initWithJson(json: replyMessage),
              let metadata = repliedCommand.metadata else {
            return
        }
        
        do {
            let video = try self.jsDecoder.decode(TPYTVideo.self, from: metadata)
            DispatchQueue.main.async {
                completion(video, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    private func handleGettingCurrentVideoReponse(replyMessage: [String: Any], completion: @escaping (TPYTItemResource?, TPPlayerState, TPPlayerTime, Color?, Error?) -> Void) {
        guard let repliedCommand = TPCommand.initWithJson(json: replyMessage),
              let jsMetadata = repliedCommand.jsonMetadata,
              let jsVideo = jsMetadata[kVideoData],
              let metadataVideo = try? JSONSerialization.data(withJSONObject: jsVideo),
              let stateInt = jsMetadata[kPlayerState] as? Int,
              let time = jsMetadata[kTime] as? Float,
              let duration = jsMetadata[kDuration] as? Float,
              let hexColor = jsMetadata[kColor] as? UInt else {
            DispatchQueue.main.async {
                completion(nil, .unknown, .zero, nil, AWTPWCSessionCommandsError.videoNotFound)
            }
            
            return
        }
        
        do {
            let color = Color(cgColor: CGColor.initWithHex(hex: hexColor))
            let state = TPPlayerState(rawValue: stateInt) ?? .unknown
            let video = try self.jsDecoder.decode(TPYTVideo.self, from: metadataVideo)
            let time = TPPlayerTime(time: time, duration: duration)
            DispatchQueue.main.async {
                completion(video, state, time, color, nil)
            }
        } catch {
            DispatchQueue.main.async {
                completion(nil, .unknown, .zero, nil, error)
            }
        }
    }
}
