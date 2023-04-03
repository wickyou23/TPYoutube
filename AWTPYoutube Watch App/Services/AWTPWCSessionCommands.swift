//
//  AWTPWCSessionCommands.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import WatchConnectivity

enum AWTPWCSessionCommandsError: Error {
    case videoNotFound
}

class AWTPWCSessionCommands {
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
    
    func getSearchingVideos(completion: @escaping (TPYTPaging<TPYTVideo>?, Error?) -> Void) {
        let command = TPCommand(command: .getSearchingVideo, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            [weak self] replyMessage in
            guard let self = self else { return }
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
    
    func playVideo(at video: TPYTItemResource, completion: @escaping (Bool, Error?) -> Void) {
        let command = TPCommand(command: .playVideo, phrase: .sent, metadata: ["videoId": video.id])
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
                completion(jsonMetadata["isPlayed"] as! Bool, nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func pauseVideo(completion: @escaping (Bool, Error?) -> Void) {
        let command = TPCommand(command: .pauseVideo, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            replyMessage in
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }) { error in
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
    
    func nextVideo(completion: @escaping (TPYTItemResource?, Error?) -> Void) {
        let command = TPCommand(command: .nextVideo, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            [weak self] replyMessage in
            guard let self = self else { return }
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
        }) { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
    
    func backVideo(completion: @escaping (TPYTItemResource?, Error?) -> Void) {
        let command = TPCommand(command: .nextVideo, phrase: .sent)
        guard WCSession.default.activationState == .activated,
              let jsCommand = command.toJson() else {
            eLog("WCSession is not activated yet!")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: {
            [weak self] replyMessage in
            guard let self = self else { return }
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
        }) { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }
    }
}
