//
//  TPYTPlayerViewState.swift
//  TPYoutube
//
//  Created by Thang Phung on 04/04/2023.
//

import Foundation

#if os(iOS)
import YouTubeiOSPlayerHelper
import MobileVLCKit
#endif

enum TPPlayerState: Int {
    case loadingDetails, ready, unStarted, ended, playing, paused, buffering, cued, stopped, unknown
    
#if os(iOS)
    static func convertState(ytState: YTPlayerState) -> TPPlayerState {
        switch ytState {
        case .unstarted:
            return .unStarted
        case .ended:
            return .ended
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .buffering:
            return .buffering
        case .cued:
            return .cued
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    
    static func convertState(vlcState: VLCMediaPlayerState) -> TPPlayerState {
        switch vlcState {
        case .stopped:
            return .stopped
        case .ended:
            return .ended
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .buffering:
            return .buffering
        case .opening, .esAdded:
            return .ready
        default:
            return .unknown
        }
    }
#endif
    
    func getIconPlay() -> String {
        switch self {
        case .playing:
            return "pause.circle.fill"
        default:
            return "play.circle.fill"
        }
    }
    
    func getMinimizeIconPlay() -> String {
        switch self {
        case .playing:
            return "pause.fill"
        default:
            return "play.fill"
        }
    }
}
