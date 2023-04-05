//
//  TPWCSessionCommand.swift
//  TPYoutube
//
//  Created by Thang Phung on 05/04/2023.
//

import Foundation
import WatchConnectivity
import SwiftUI

struct TPWCSessionCommands {
    private let jsEncoder: JSONEncoder
    private let jsDecoder: JSONDecoder
    
    init() {
        self.jsEncoder = JSONEncoder()
        self.jsEncoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        
        self.jsDecoder = JSONDecoder()
        self.jsDecoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
    }
    
    func notifyNewSearchingVideos() {
        guard WCSession.default.activationState == .activated else {
            eLog("WCSession is not activated yet")
            return
        }
        
        guard let metadata = TPStorageManager.yt.getSearchingVideoPage(type: Data.self) else {
            eLog("New searching videos not found")
            return
        }
        
        let command = TPCommand(command: .getSearchingVideo, phrase: .notify, metadata: metadata)
        guard let jsCommand = command.toJson() else {
            eLog("Json convert failed")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in })
    }
    
    func notifyPlayControl() {
        guard WCSession.default.activationState == .activated else {
            eLog("WCSession is not activated yet")
            return
        }
        
        let command = TPCommand(command: .playControl, phrase: .notify)
        guard let jsCommand = command.toJson() else {
            eLog("Json convert failed")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in })
    }
    
    func notifyPauseControl() {
        guard WCSession.default.activationState == .activated else {
            eLog("WCSession is not activated yet")
            return
        }
        
        let command = TPCommand(command: .pauseControl, phrase: .notify)
        guard let jsCommand = command.toJson() else {
            eLog("Json convert failed")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in })
    }
    
    func notifyLoadVideo(video: TPYTItemResource) {
        guard WCSession.default.activationState == .activated else {
            eLog("WCSession is not activated yet")
            return
        }
        
        guard let metadata = try? jsEncoder.encode(video) else {
            eLog("Cannot convert metadata")
            return
        }
        
        let command = TPCommand(command: .loadVideo, phrase: .notify, metadata: metadata)
        guard let jsCommand = command.toJson() else {
            eLog("Json convert failed")
            return
        }
        
        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in })
    }
    
    func notifyAverageColorOfCurrentVideo(cgColor: CGColor) {
        guard WCSession.default.activationState == .activated else {
            eLog("WCSession is not activated yet")
            return
        }
        
        let command = TPCommand(command: .averageColorOfCurrentVideo, phrase: .notify, metadata: ["Color": cgColor.toInt()])
        guard let jsCommand = command.toJson() else {
            eLog("Json convert failed")
            return
        }

        WCSession.default.sendMessage(jsCommand, replyHandler: { _ in })
    }
}
