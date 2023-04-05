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
import WatchConnectivity

@main
struct TPYoutubeApp: App {
    @UIApplicationDelegateAdaptor(TPYoutubeAppDelegate.self) var appDelegate
    
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
