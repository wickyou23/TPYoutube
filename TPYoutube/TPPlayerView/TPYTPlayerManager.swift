//
//  TPPlayerViewModel.swift
//  TPYoutube
//
//  Created by Thang Phung on 08/03/2023.
//

import Foundation
import YouTubeiOSPlayerHelper
import AVFoundation
import MediaPlayer
import MobileVLCKit
import Combine

enum TPYTPlayerViewState {
    case loadingDetails, ready, unStarted, ended, playing, paused, buffering, cued, stopped, unknown
    
    static func convertState(ytState: YTPlayerState) -> TPYTPlayerViewState {
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
    
    static func convertState(vlcState: VLCMediaPlayerState) -> TPYTPlayerViewState {
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

class TPYTPlayerManager: NSObject, ObservableObject {
    static let shared = TPYTPlayerManager()
    
    @Published var state: TPYTPlayerViewState = .unknown
    @Published var playertime: TPYTPlayerTime = .init(time: 0, duration: 0)
    @Published var action: TPYTPlayerViewAction = .noAction
    @Published var isPresented = false
    @Published var currentVideo: TPYTItemResource?
    @Published var playerType: TPYTPlayerType = .undefined
    
    private var appDidEnterBackground = false
    private var videoDuration: Float = 0
    private var videoPlaytime: Float = 0
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var subscriptions = Set<AnyCancellable>()
    private var vlcMediaMetaData: TPVLCMetaData = .init()
    
    var isPlaying: Bool {
        switch playerType {
        case .vlc:
            return vlcPlayer.isPlaying
        case .ytBrowser:
            return state == .playing
        case .undefined:
            return false
        }
    }
    
    var isPlayerReady: Bool {
        state != .unknown && state != .loadingDetails && state != .buffering
    }
    
    lazy var ytPlayer: YTPlayerView = {
        let player = YTPlayerView()
        player.delegate = self
        return player
    }()
    
    lazy var vlcPlayerUIView: TPVLCPAudiolaybackView = {
        let uiView = TPVLCPAudiolaybackView()
        uiView.vlcPlayer.delegate = self
        return uiView
    }()
    
    var vlcPlayer: VLCMediaPlayer {
        vlcPlayerUIView.vlcPlayer
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    func load(video: TPYTItemResource) {
        TPStorageManager.shared.addVideoToHistory(video: video)
        currentVideo = video
        state = .loadingDetails
        
        if video.videoV1 == nil {
            TPYTAPIManager.ytService.getVideoV1(videoId: video.id)
                .timeout(5, scheduler: DispatchQueue.global())
                .sink { completion in
                    guard case let .failure(error) = completion else { return }
                    eLog("\(error.localizedDescription)")
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.state = .unknown
                        self.playerType = .ytBrowser
                        self.loadCurrentVideo()
                    }
                } receiveValue: {
                    [weak self] videoV1 in
                    TPStorageManager.shared.saveVideoV1ById(videoId: video.id, videoV1: videoV1)
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.state = .unknown
                        self.playerType = .vlc
                        self.loadCurrentVideo()
                    }
                }
                .store(in: &subscriptions)
        }
        else {
            state = .unknown
            playerType = .vlc
            loadCurrentVideo()
        }
    }
    
    private func loadCurrentVideo() {
        guard let crVideo = currentVideo else {
            eLog("Current video not found")
            return
        }
        
        cleanPlayer()
        
        switch playerType {
        case .vlc:
            guard let videoV1 = crVideo.videoV1, let audioUrl = videoV1.getAudioURL() else {
                eLog("Not found audio link, try to play with browser")
                self.playerType = .ytBrowser
                self.loadCurrentVideo()
                return
            }
            
            let vlcMedia = VLCMedia(url: audioUrl)
            vlcPlayer.media = vlcMedia
            vlcMediaMetaData.updateMetadataFromMedia(video: crVideo, mediaPlayer: vlcPlayer)
            state = .ready
        case .ytBrowser:
            ytPlayer.load(withVideoId: crVideo.id, playerVars: ["height": 144, "width": 256])
        case .undefined:
            return
        }
        
        setupRemoteTransportControls()
        
        if !isPresented {
            isPresented = true
        }
    }
    
    func play() {
        switch playerType {
        case .vlc:
            vlcPlayer.play()
        case .ytBrowser:
            ytPlayer.playVideo()
        case .undefined:
            return
        }
    }
    
    func pause() {
        switch playerType {
        case .vlc:
            vlcPlayer.pause()
        case .ytBrowser:
            ytPlayer.pauseVideo()
        case .undefined:
            return
        }
    }
    
    func seekToTime(time: Float) {
        switch playerType {
        case .vlc:
            let positionDiff = Double(time) - self.vlcMediaMetaData.elapsedPlaybackTime
            vlcPlayer.jumpForward(Int32(positionDiff))
        case .ytBrowser:
            ytPlayer.seek(toSeconds: time, allowSeekAhead: true)
        case .undefined:
            return
        }
    }
    
    func next10() {
        switch playerType {
        case .vlc:
            vlcPlayer.jumpForward(10)
        case .ytBrowser:
            ytPlayer.seek(toSeconds: min(playertime.time + 10, playertime.duration), allowSeekAhead: true)
        case .undefined:
            return
        }
    }
    
    func back10() {
        switch playerType {
        case .vlc:
            vlcPlayer.jumpBackward(10)
        case .ytBrowser:
            ytPlayer.seek(toSeconds: max(playertime.time - 10, 0), allowSeekAhead: true)
        case .undefined:
            return
        }
    }
    
    func cleanPlayer() {
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        vlcMediaMetaData = .init()
        playertime = .zero
        
        switch playerType {
        case .vlc:
            vlcPlayer.media = nil
        case .ytBrowser:
            ytPlayer.removeWebView()
        case .undefined:
            return
        }
    }
    
    private func getCachedImage(from request: URLRequest) -> UIImage? {
        guard let cachedResponse = URLCache.imageCache.cachedResponse(for: request),
              let image = UIImage(data: cachedResponse.data) else { return nil }
        return image
    }
    
    private func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 10)]
        commandCenter.skipForwardCommand.addTarget { [unowned self] _ in
            if isPlaying {
                next10()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 10)]
        commandCenter.skipBackwardCommand.addTarget {
            [unowned self] _ in
            if isPlaying {
                back10()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.playCommand.addTarget {
            [unowned self] _ in
            if !isPlaying {
                play()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.pauseCommand.addTarget {
            [unowned self] _ in
            if isPlaying {
                pause()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget {
            [unowned self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent,
                isPlaying {
                seekToTime(time: Float(event.positionTime))
                return .success
            }
            
            
            return .commandFailed
        }
    }
}

extension TPYTPlayerManager {
    func getStateIcon() -> String {
        if isPlaying {
            return TPYTPlayerViewState.playing.getIconPlay()
        }
        
        return state.getIconPlay()
    }
    
    func getMinimizeIconPlay() -> String {
        if isPlaying {
            return TPYTPlayerViewState.playing.getMinimizeIconPlay()
        }
        
        return state.getMinimizeIconPlay()
    }
}

extension TPYTPlayerManager: YTPlayerViewDelegate {
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .paused:
            iLog("Video has paused")
            if appDidEnterBackground {
                iLog("Play again")
                playerView.playVideo()
            }
        default:
            iLog("playerView State: \(String(describing: state))")
        }
        
        DispatchQueue.main.async {
            [weak self] in
            self?.state = TPYTPlayerViewState.convertState(ytState: state)
        }
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView, andPlayDuration duration: Float) {
        iLog("playerViewDidBecomeReady and duration \(duration.rounded())")
        //        playerView.playVideo()
        
        videoDuration = duration
        DispatchQueue.main.async {
            [weak self] in
            self?.state = .ready
            self?.playertime = TPYTPlayerTime(time: 0, duration: duration.rounded())
        }
    }
    
    @objc func appDidEnterBackground(_ notification: Notification) {
        iLog("appDidEnterBackground")
        appDidEnterBackground = true
    }
    
    @objc func appDidBecomeActive(_ notification: Notification) {
        iLog("appDidBecomeActive")
        appDidEnterBackground = false
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        iLog("\(#function)[Playtime]: \(playTime.rounded())")
        videoPlaytime = playTime
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.playertime = TPYTPlayerTime(time: playTime.rounded(), duration: self.videoDuration)
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayDuration duration: Float) {
        iLog("\(#function)[PlayDuration]: \(duration)")
    }
}

extension TPYTPlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let currentVideo = currentVideo else { return }
        
        
        switch vlcPlayer.state {
        case .buffering:
            state = vlcPlayer.isPlaying ? .playing : .buffering
            vlcPlayer.media?.delegate = self
            let playbackDuration = Double(vlcPlayer.media!.length.intValue / 1000)
            if let elapsedPlaybackTime = vlcPlayer.time.value {
                let playbackTime = elapsedPlaybackTime.doubleValue / 1000
                iLog("[VLC PlayerTime] \(playbackTime) - \(playbackDuration)")
                playertime = TPYTPlayerTime(time: Float(playbackTime), duration: Float(playbackDuration))
            }
            else {
                playertime = TPYTPlayerTime(time: 0, duration: Float(playbackDuration))
            }
        default:
            state = TPYTPlayerViewState.convertState(vlcState: vlcPlayer.state)
            break
        }
        
        vlcMediaMetaData.updateMetadataFromMedia(video: currentVideo,
                                                 mediaPlayer: vlcPlayer)
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        let playbackDuration = Double(vlcPlayer.media!.length.intValue / 1000)
        if let elapsedPlaybackTime = vlcPlayer.time.value {
            let playbackTime = elapsedPlaybackTime.doubleValue / 1000
            iLog("[VLC PlayerTime] \(playbackTime) - \(playbackDuration)")
            playertime = TPYTPlayerTime(time: Float(playbackTime), duration: Float(playbackDuration))
        }
    }
}

extension TPYTPlayerManager: VLCMediaDelegate {
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
        guard let currentVideo = currentVideo else { return }
        
        vlcMediaMetaData.updateMetadataFromMedia(video: currentVideo,
                                                 mediaPlayer: vlcPlayer)
    }
}
