//
//  TPYoutubeAppDelegate.swift
//  TPYoutube
//
//  Created by Thang Phung on 04/04/2023.
//

import Foundation
import SwiftUI
import CocoaLumberjackSwift
import WatchConnectivity

class TPYoutubeAppDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
        
        AppViewModel.shared.configurateEnviroment()
        TPGGAuthManager.shared.checkSession()
        TPStorageManager.shared.configuration()
        
        //Setup log
        #if DEBUG
        DDLog.add(DDOSLogger.sharedInstance)
        #else
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        #endif
        
        //Setup WCSession
        if WCSession.isSupported() {
            WCSession.default.delegate = AppViewModel.shared.wcSessionDelegator
            WCSession.default.activate()
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.applicationDidEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        TPWCSessionCommands().notifyAppDidEnterBackground()
    }
}
