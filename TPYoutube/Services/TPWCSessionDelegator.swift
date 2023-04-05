//
//  TPWCSessionDelegator.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import WatchConnectivity

class TPWCSessionDelegator: NSObject, WCSessionDelegate {
    private let handler = TPWCSessionHandler()
    private let appVM = AppViewModel.shared
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        iLog("activationState \(activationState)")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        iLog("activationState \(session.activationState)")
        
        appVM.setWCSessionState(newState: session.activationState)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handler.handleCommandRecived(command: message, replyHandler: replyHandler)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        iLog("activationState = \(session.activationState)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        iLog("activationState = \(session.activationState)")
    }
}
