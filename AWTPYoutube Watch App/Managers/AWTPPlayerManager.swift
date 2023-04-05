//
//  AWTPPlayerManager.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 04/04/2023.
//

import Foundation
import SwiftUI

class AWTPPlayerManager: ObservableObject {
    static let shared = AWTPPlayerManager()
    
    @Published private(set) var state: TPPlayerState = .loadingDetails
    @Published private(set) var video: TPYTItemResource!
    @Published var readyToNavigate = false
    @Published var averageColorOfCurrentVideo = TPTheme.shared.appColor
    
    private let wcCommand = AWTPWCSessionCommands()
    
    var isPlaying: Bool { state == .playing }
    var isLoadingDetails: Bool { state == .loadingDetails }
    
    func loadVideo(video: TPYTItemResource) {
        self.video = video
        self.state = .loadingDetails
        readyToNavigate = true
        
        wcCommand.loadVideo(at: video) {
            isPlayed, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
        }
    }
    
    func playControl() {
        wcCommand.playControl {
            isPaused, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
        }
    }
    
    func pauseControl() {
        wcCommand.pauseControl {
            isPaused, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
        }
    }
    
    func nextControl() {
        wcCommand.nextControl {
            [weak self] video, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.video = video!
        }
    }
    
    func backControl() {
        wcCommand.backControl {
            [weak self] video, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.video = video!
        }
    }
    
    func setPlayerState(newState: TPPlayerState) {
        DispatchQueue.main.async {
            [weak self] in
            self?.state = newState
        }
    }
    
    func setNewVideo(newVideo: TPYTItemResource) {
        DispatchQueue.main.async {
            [weak self] in
            self?.video = newVideo
            self?.state = .playing
            self?.readyToNavigate = true
        }
    }
    
    func setAverageColorOfCurrentVideo(color: Color) {
        DispatchQueue.main.async {
            [weak self] in
            self?.averageColorOfCurrentVideo = color
        }
    }
}
