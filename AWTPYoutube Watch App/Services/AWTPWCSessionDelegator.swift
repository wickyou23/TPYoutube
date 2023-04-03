//
//  AWTPWCSessionDelegator.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import WatchConnectivity

class AWTPWCSessionDelegator: NSObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        iLog("activationState \(activationState)")
    }
}
