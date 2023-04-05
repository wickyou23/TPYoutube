//
//  ContentView.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import SwiftUI
import WatchKit

private let VIDEOS_TAB = 0
private let PLAYER_TAB = 1

struct ContentView: View {
    @State private var readyToNavigate: Bool = false
    @State private var selectionTabView = VIDEOS_TAB
    
    var body: some View {
        TabView(selection: $selectionTabView) {
            NavigationView {
                AWTPYTSearchView()
            }
            .tag(VIDEOS_TAB)
                
            AWTPPlayerView()
                .tag(PLAYER_TAB)
        }
        .tabViewStyle(.page)
        .onReceive(AWTPPlayerManager.shared.$readyToNavigate, perform: {
            newValue in
            if newValue && selectionTabView != PLAYER_TAB {
                selectionTabView = PLAYER_TAB
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
