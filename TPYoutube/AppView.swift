//
//  AppView.swift
//  TPYoutube
//
//  Created by Thang Phung on 21/02/2023.
//

import SwiftUI
import YouTubeiOSPlayerHelper
import Introspect

struct AppView: View {
    @EnvironmentObject private var theme: TPTheme
    
    var body: some View {
        #if os(watchOS)
        VStack {
            Text("Hello AWTPYoutube")
        }
        #else
        TabView {
            NavigationView {
                TPYTSearchView()
            }
            .tabItem {
                Label("Search Videos", systemImage: "magnifyingglass")
                    .appFont()
            }

            NavigationView {
                TPYTPlaylistView()
            }
            .tabItem {
                Label("List", systemImage: "list.and.film")
                    .appFont()
            }
        }
        .modifier(TPPlayerViewModifier())
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.appColor)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: UIFont(name: theme.fontName, size: 10)!,
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(theme.appColor)
            ]

            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        #endif
    }
}

struct Appview_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
            .environmentObject(TPTheme.shared)
            .environmentObject(TPGGAuthManager.shared)
            .environmentObject(TPYTPlayerManager.shared)
    }
}
