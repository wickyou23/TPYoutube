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

protocol ITPYTPlayerAction {
    func play()
    func pause()
    func seekToTime(time: Float)
    func next10()
    func back10()
    func nextSong()
    func backSong()
    func closePlayer()
}

class TPYTPlayerManager: NSObject, ObservableObject {
    static let shared = TPYTPlayerManager()
    
    @Published var playertime: TPYTPlayerTime = .init(time: 0, duration: 0)
    @Published var isPresented = false
    @Published var playerType: TPYTPlayerType = .undefined
    
    @Published private(set) var state: TPYTPlayerViewState = .unknown
    @Published private(set) var currentVideo: TPYTItemResource?
    
    private var appDidEnterBackground = false
    private var videoDuration: Float = 0
    private var videoPlaytime: Float = 0
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var subscriptions = Set<AnyCancellable>()
    private var vlcMediaMetaData: TPVLCMetaData = .init()
    private var playlist: [TPYTItemResource] = []
    private var currentIndexVideo: Int = 0
    
    var isAutoPlay = true
    var isLoopList = false
    var isPlaylist: Bool { playlist.count > 1 }
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
        uiView.delegate = self
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
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAudioInterruption(_:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
    }
    
    func load(video: TPYTItemResource,
              playlist: [TPYTItemResource],
              isAutoPlay: Bool = true,
              isRandomOrder: Bool = false,
              isLoopList: Bool = true) {
        currentIndexVideo = playlist.firstIndex(where: { $0.id == video.id }) ?? 0
        self.playlist = playlist
        self.isLoopList = isLoopList
        self.isAutoPlay = isAutoPlay
        
        setupRemoteTransportControls()
        
        load(video: video)
    }
    
    private func load(video: TPYTItemResource) {
        TPStorageManager.shared.addVideoToHistory(video: video)
        currentVideo = video
        state = .loadingDetails
        
        if !isPresented {
            isPresented = true
        }
        
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
            vlcPlayer.media?.delegate = self
            state = .ready
            if isAutoPlay {
                vlcPlayer.play()
            }
        case .ytBrowser:
            ytPlayer.load(withVideoId: crVideo.id, playerVars: ["height": 144, "width": 256])
        case .undefined:
            return
        }
    }
    
    private func cleanPlayer() {
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
        
        commandCenter.nextTrackCommand.isEnabled = isPlaylist
        commandCenter.nextTrackCommand.addTarget { [unowned self] _ in
            self.nextSong()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = isPlaylist
        commandCenter.previousTrackCommand.addTarget { [unowned self] _ in
            self.backSong()
            return .success
        }
        
        commandCenter.skipForwardCommand.isEnabled = !isPlaylist
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 10)]
        commandCenter.skipForwardCommand.addTarget { [unowned self] _ in
            if isPlaying {
                next10()
                return .success
            }
            
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.isEnabled = !isPlaylist
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

extension TPYTPlayerManager: ITPYTPlayerAction {
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
    
    func nextSong() {
        guard !playlist.isEmpty else {
            return
        }
        
        currentIndexVideo += 1
        if currentIndexVideo >= playlist.count, isLoopList {
            currentIndexVideo = 0
        }
        
        load(video: playlist[currentIndexVideo])
    }
    
    func backSong() {
        guard !playlist.isEmpty else {
            return
        }
        
        currentIndexVideo -= 1
        if currentIndexVideo < 0, isLoopList {
            currentIndexVideo = playlist.count - 1
        }
        
        load(video: playlist[currentIndexVideo])
    }
    
    func closePlayer() {
        currentVideo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        cleanPlayer()
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
    
    @objc func appDidEnterBackground(_ notification: Notification) {
        iLog("I'm in background")
        appDidEnterBackground = true
    }
    
    @objc func appDidBecomeActive(_ notification: Notification) {
        iLog("I'm wakeup")
        appDidEnterBackground = false
    }
    
    @objc func handleSilenceSecondaryAudioHintNotification(_ notification: Notification) {
        iLog("Another app is playing their audio")
        guard let info = notification.userInfo,
              let isPlayingSecondaryAudio = info[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? Bool else {
            return
        }
        
        if isPlayingSecondaryAudio && isPlaying {
            self.pause()
        }
        else if isAutoPlay && !isPlayingSecondaryAudio && !isPlaying {
            self.play()
        }
    }   
    
    @objc func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue),
              let _ = currentVideo else {
            return
        }
        
        switch type {
        case .began:
            guard isPlaying else { return }
            iLog("[PAUSE] Another app is playing their audio")
            self.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume), !isPlaying {
                iLog("[RESUME] Another app is playing their audio")
                self.play()
            }
        default:
            break
        }
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
        if isAutoPlay {
            playerView.playVideo()
        }
        
        videoDuration = duration
        DispatchQueue.main.async {
            [weak self] in
            self?.state = .ready
            self?.playertime = TPYTPlayerTime(time: 0, duration: duration.rounded())
        }
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
        defer {
            if let currentVideo = currentVideo,
               let media = vlcPlayer.media,
               (media.length.intValue / 1000) > 0,
               vlcPlayer.isPlaying {
                vlcMediaMetaData.updateMetadataFromMedia(video: currentVideo,
                                                         mediaPlayer: vlcPlayer)
            }
        }
        
        guard let _ = currentVideo else { return }
        
        switch vlcPlayer.state {
        case .buffering:
            state = vlcPlayer.isPlaying ? .playing : .buffering
            let playbackDuration = Double(vlcPlayer.media!.length.intValue / 1000)
            if let elapsedPlaybackTime = vlcPlayer.time.value {
                let playbackTime = elapsedPlaybackTime.doubleValue / 1000
                iLog("\(playbackTime) - \(playbackDuration)")
                playertime = TPYTPlayerTime(time: Float(playbackTime), duration: Float(playbackDuration))
            }
            else {
                playertime = TPYTPlayerTime(time: 0, duration: Float(playbackDuration))
            }
            
            return
        case .ended:
            playertime = TPYTPlayerTime(time: playertime.time + 1, duration: playertime.duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                [unowned self] in
                self.nextSong()
            }
        default:
            break
        }
        
        state = TPYTPlayerViewState.convertState(vlcState: vlcPlayer.state)
        iLog("State changed: \(state)")
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let media = vlcPlayer.media else { return }
        let playbackDuration = Double(media.length.intValue / 1000)
        if let elapsedPlaybackTime = vlcPlayer.time.value {
            let playbackTime = elapsedPlaybackTime.doubleValue / 1000
            iLog("[VLC PlayerTime] \(playbackTime) - \(playbackDuration)")
            playertime = TPYTPlayerTime(time: Float(playbackTime), duration: Float(playbackDuration))
        }
    }
}

extension TPYTPlayerManager: VLCMediaDelegate {
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
        //        guard let currentVideo = currentVideo else { return }
        //        vlcMediaMetaData.updateMetadataFromMedia(video: currentVideo,
        //                                                 mediaPlayer: vlcPlayer)
    }
}

extension TPYTPlayerManager: TPVLCPAudiolaybackViewDelegate {
    func mediaPlayerMediaChanged(newMedia: VLCMedia) {
        iLog("mediaPlayerMediaChanged")
        
        guard let currentVideo = currentVideo else { return }
        vlcMediaMetaData = .init()
        vlcMediaMetaData.updateMetadataFromMedia(video: currentVideo,
                                                 mediaPlayer: vlcPlayer)
    }
}
