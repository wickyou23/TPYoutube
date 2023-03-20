//
//  TPYTBrowserPlayerView.swift
//  TPYoutube
//
//  Created by Thang Phung on 16/03/2023.
//

import Foundation
import YouTubeiOSPlayerHelper
import SwiftUI

struct TPYTBrowserPlayerView: UIViewRepresentable {
    @EnvironmentObject private var player: TPYTPlayerManager
    
    func makeUIView(context: Context) -> YTPlayerView {
        return player.ytPlayer
    }
    
    func updateUIView(_ uiView: YTPlayerView, context: Context) {
    }
}
