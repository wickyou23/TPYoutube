//
//  TPYTPlayerView.swift
//  TPYoutube
//
//  Created by Thang Phung on 23/02/2023.
//

import Foundation
import SwiftUI
import YouTubeiOSPlayerHelper

enum TPYTPlayerViewAction {
    case play, pause, next10, back10, seek(Float), noAction
}

enum TPYTPlayerType {
    case vlc, ytBrowser, undefined
}

struct TPYTPlayerView: View {
    @EnvironmentObject private var player: TPYTPlayerManager
    
    var body: some View {
        VStack {
            switch player.playerType {
            case .ytBrowser:
                TPYTBrowserPlayerView()
            case .vlc:
                TPVLCPlayerView()
            case .undefined:
                EmptyView()
            }
        }
    }
}
