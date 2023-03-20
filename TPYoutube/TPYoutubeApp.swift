//
//  TPYoutubeApp.swift
//  TPYoutube
//
//  Created by Thang Phung on 21/02/2023.
//

import SwiftUI
import AVKit
import MobileVLCKit
import CocoaLumberjackSwift

@main
struct TPYoutubeApp: App {
    @UIApplicationDelegateAdaptor(MyAppDelegate.self) var appDelegate
    
    @StateObject private var theme = TPTheme.shared
    @StateObject private var ggAuth = TPGGAuthManager.shared
    @StateObject private var appVM = AppViewModel.shared
    
    var body: some Scene {
        WindowGroup {
            AppView()
                .modifier(logoutPopup)
                .environmentObject(theme)
                .environmentObject(ggAuth)
                .environmentObject(appVM)
//            .environment(\.colorScheme, .dark)
        }
    }
    
    var logoutPopup: some ViewModifier {
        Popup(isPresented: $appVM.isShowPopupLogout, title: "Logout", message: "Do you want to logout?") {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                ggAuth.logout()
            }
        }
    }
}

class MyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
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
        
        return true
    }
}
