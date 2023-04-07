//
//  AWTPPlayerManager.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 04/04/2023.
//

import Foundation
import SwiftUI
import Combine

class AWTPPlayerManager: ObservableObject {
    static let shared = AWTPPlayerManager()
    
    @Published private(set) var state: TPPlayerState = .unknown
    @Published private(set) var video: TPYTItemResource!
    @Published var readyToNavigate = false
    @Published var averageColorOfCurrentVideo = TPTheme.shared.appColor
    @Published var playerTime: TPPlayerTime = .zero
    
    private let wcCommand = AWTPWCSessionCommands()
    private var didBecomeActiveTasks = [DispatchWorkItem]()
    private let appVM = AWTPYoutubeAppVideModel.shared
    private var cancellables = [AnyCancellable]()
    
    var isPlaying: Bool { state == .playing }
    var isLoadingDetails: Bool { state == .loadingDetails }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive(_:)),
                                               name: WKApplication.didBecomeActiveNotification,
                                               object: nil)
        
        appVM.$wcSessionState.sink {
            [weak self] newState in
            guard let self = self else { return }
            if newState == .activated && !self.didBecomeActiveTasks.isEmpty {
                DispatchQueue.global().async(flags: .barrier) {
                    [weak self] in
                    guard let self = self else { return }
                    for task in self.didBecomeActiveTasks {
                        DispatchQueue.main.async(execute: task)
                    }
                    
                    self.didBecomeActiveTasks = []
                }
            }
        }
        .store(in: &cancellables)
    }
    
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
        guard let _ = video else { return }
        
        wcCommand.playControl {
            isPaused, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
        }
    }
    
    func pauseControl() {
        guard let _ = video else { return }
        
        wcCommand.pauseControl {
            isPaused, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                return
            }
        }
    }
    
    func nextControl() {
        guard let _ = video else { return }
        
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
        guard let _ = video else { return }
        
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
    
    func setNewTime(time: TPPlayerTime) {
        DispatchQueue.main.async {
            [weak self] in
            self?.playerTime = time
        }
    }
    
    func setAverageColorOfCurrentVideo(color: Color) {
        DispatchQueue.main.async {
            [weak self] in
            self?.averageColorOfCurrentVideo = color
        }
    }
    
    func closePlayer() {
        DispatchQueue.main.async {
            [weak self] in
            self?.video = nil
            self?.state = .unknown
            self?.playerTime = .zero
            self?.averageColorOfCurrentVideo = TPTheme.shared.appColor
        }
    }
    
    func getCurrentVideoIsPlaying() {
        wcCommand.getCurrentVideoIsPlaying {
            [weak self] currentVideo, state, time, color, error in
            if let error = error {
                eLog("\(error.localizedDescription)")
                self?.closePlayer()
                return
            }
            
            DispatchQueue.main.async {
                [weak self] in
                self?.readyToNavigate = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                [weak self] in
                self?.video = currentVideo!
                self?.state = state
                self?.playerTime = time
                self?.averageColorOfCurrentVideo = color ?? TPTheme.shared.appColor
            }
        }
    }
}

extension AWTPPlayerManager {
    @objc private func appDidBecomeActive(_ notification: Notification) {
        let actionBlock = {
            [weak self] in
            guard let self = self else { return }
            self.getCurrentVideoIsPlaying()
        }
        
        if appVM.wcSessionState == .activated {
            actionBlock()
        }
        else {
            let task = DispatchWorkItem(block: actionBlock)
            didBecomeActiveTasks.append(task)
        }
    }
}
