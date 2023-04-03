//
//  AWTPPlayerViewModel.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation

enum AWTPPlayerViewModelState {
    case play, pause, loading
}

class AWTPPlayerViewModel: ObservableObject {
    @Published var state: AWTPPlayerViewModelState = .pause
    
    private let wcCommand = AWTPWCSessionCommands()
    
    var video: TPYTItemResource
    
    init(video: TPYTItemResource) {
        self.video = video
    }
    
    func playVideo() {
        state = .play
        wcCommand.playVideo(at: video) {
            [weak self] isPlayed, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.state = isPlayed ? .play : .pause
        }
    }
    
    func pauseVideo() {
        state = .pause
        wcCommand.pauseVideo {
            [weak self] isPaused, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.state = isPaused ? .pause : .play
        }
    }
    
    func nextVideo() {
        state = .loading
        wcCommand.nextVideo {
            [weak self] video, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.video = video!
            self.state = .play
        }
    }
    
    func preVideo() {
        state = .loading
        wcCommand.backVideo {
            [weak self] video, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
            
            self.video = video!
            self.state = .play
        }
    }
}
