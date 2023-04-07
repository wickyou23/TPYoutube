//
//  AWTPYoutubeApp.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import SwiftUI

@main
struct AWTPYoutubeWatchApp: App {
    @WKApplicationDelegateAdaptor(AWTPApplicationDelegate.self) private var appDelegate
    
    @StateObject private var theme = TPTheme.shared
    @StateObject private var appVM = AWTPYoutubeAppVideModel.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .environmentObject(appVM)
        }
    }
}
