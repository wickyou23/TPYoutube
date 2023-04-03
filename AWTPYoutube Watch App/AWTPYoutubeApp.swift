//
//  AWTPYoutubeApp.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import SwiftUI

@main
struct AWTPYoutube_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AWTPApplicationDelegate.self) private var appDelegate
    
    @StateObject private var theme = TPTheme.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
        }
    }
}
