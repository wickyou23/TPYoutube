//
//  AppViewModel.swift
//  TPYoutube
//
//  Created by Thang Phung on 20/03/2023.
//

import Foundation
import Combine

struct TPAppKeys {
    let authURLScheme: String
    let clientID: String
    let innerYoutubeAPIKey: String
    let youtubeAPIKey: String
}

class AppViewModel: ObservableObject {
    static let shared = AppViewModel()
    
    @Published var isShowPopupLogout = false
    
    lazy var wcSessionDelegator = {
        TPWCSessionDelegator()
    }()
    
    private var _appKeys: TPAppKeys!
    static var appKeys: TPAppKeys {
        return shared._appKeys
    }
    
    func configurateEnviroment() {
        _appKeys = loadKeys()
    }
    
    func showPopupLogout() {
        isShowPopupLogout = true
    }
    
    private func loadKeys() -> TPAppKeys? {
        guard let path = Bundle.main.path(forResource: "TPKeys", ofType: "plist"),
              let nsDictionary = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        
        return TPAppKeys(authURLScheme: nsDictionary["authURLScheme"] as! String,
                         clientID: nsDictionary["clientID"] as! String,
                         innerYoutubeAPIKey: nsDictionary["innerYoutubeAPIKey"] as! String,
                         youtubeAPIKey: nsDictionary["youtubeAPIKey"] as! String)
    }
}
