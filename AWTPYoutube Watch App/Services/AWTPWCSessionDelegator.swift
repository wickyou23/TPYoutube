//
//  AWTPWCSessionDelegator.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import WatchConnectivity

class AWTPWCSessionDelegator: NSObject, WCSessionDelegate {
    private let handler = AWTPWCSessionHandler()
    private let appVM = AWTPYoutubeAppVideModel.shared
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        iLog("activationState \(activationState)")
    }
    
    func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        iLog("activationState \(session.activationState)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        iLog("activationState \(session.activationState)")
        
        appVM.setWCSessionState(newState: session.activationState)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        iLog("[MESSAGE] \(message)")
        handler.handleCommandRecived(command: message, replyHandler: replyHandler)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        iLog("applicationContext \(applicationContext)")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        iLog("applicationContext \(userInfo)")
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        iLog("applicationContext \(userInfoTransfer)")
    }
}
