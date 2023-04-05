//
//  AWTPYoutubeAppVideModel.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 04/04/2023.
//

import Foundation
import WatchConnectivity

class AWTPYoutubeAppVideModel: ObservableObject {
    static let shared = AWTPYoutubeAppVideModel()
    
    @Published private(set) var wcSessionState: WCSessionActivationState = .notActivated
    
    func setWCSessionState(newState: WCSessionActivationState) {
        DispatchQueue.main.async {
            [unowned self] in
            self.wcSessionState = newState
        }
    }
}
