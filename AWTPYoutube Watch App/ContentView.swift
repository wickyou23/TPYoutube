//
//  ContentView.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import SwiftUI
import WatchKit

private let kVideoTab = 0
private let kPlayerTab = 1

struct ContentView: View {
    @State private var readyToNavigate: Bool = false
    @State private var selectionTabView = kVideoTab
    
    var body: some View {
        TabView(selection: $selectionTabView) {
            NavigationView {
                AWTPYTSearchView()
            }
            .tag(kVideoTab)
                
            AWTPPlayerView()
                .tag(kPlayerTab)
        }
        .tabViewStyle(.page)
        .onReceive(AWTPPlayerManager.shared.$readyToNavigate, perform: { newValue in
            if newValue && selectionTabView != kPlayerTab {
                selectionTabView = kPlayerTab
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
