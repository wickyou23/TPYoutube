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
import SwiftUI
import WatchConnectivity

protocol ITPYTPlayerAction {
    func play()
    func pause()
    func seekToTime(time: Float)
    func next10()
    func back10()
    func nextSong() -> TPYTItemResource?
    func backSong() -> TPYTItemResource?
    func closePlayer()
}

//MARK: - TPYTPlayerManager

private let LIMITED_RELOADING_VIDEO = 3

class TPYTPlayerManager: NSObject, ObservableObject {
    static let shared = TPYTPlayerManager()
    
    @Published var playertime: TPPlayerTime = .init(time: 0, duration: 0)
    @Published var isPresented = false
    @Published var playerType: TPYTPlayerType = .undefined
    
    @Published private(set) var state: TPPlayerState = .unknown
    @Published private(set) var currentVideo: TPYTItemResource?
    
    private var appDidEnterBackground = false
    private var videoDuration: Float = 0
    private var videoPlaytime: Float = 0
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var vlcMediaMetaData: TPVLCMetaData = .init()
    private var playlist: [TPYTItemResource] = []
    private var currentIndexVideo: Int = 0
    private var cancellables: [AnyCancellable] = []
    private var isNetworkChanged: Bool = false
    private var latestReachabilityConnection: Reachability.Connection?
    private let reachability = TPReachabilityNetwork(hostName1: "google.com",
                                                     hostName2: "baidu.com",
                                                     hostName3: "youtube.com")
    private var reloadVideoTimer: Timer?
    private var reloadVideoTime: TPPlayerTime?
    private var reloadVideoCount = 0
    private let wcCommand = TPWCSessionCommands()
    private var timeToNotifyPlayerTime: Date?
    
    private var videoV1Subscription: AnyCancellable?
    private var m3u8Subscription: AnyCancellable?
    
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
        
        reachability.tpReachabilityPublisher?
            .sink(receiveValue: self.handleReachabilityChange(_:))
            .store(in: &cancellables)
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
    
    private func load(video: TPYTItemResource, isReloading: Bool = false) {
        TPStorageManager.shared.addVideoToHistory(video: video)
        currentVideo = video
        state = .loadingDetails
        
        if !isReloading {
            cleanPlayer()
        }
        
        if !isPresented {
            isPresented = true
        }
        
        if let videoV1Exist = video.videoV1 {
            if videoV1Exist.streamingData.hasStreamingAudioURL {
                self.getM3U8URL(video: video, videoV1: videoV1Exist)
            }
            else {
                state = .unknown
                playerType = .vlc
                loadCurrentVideo()
            }
        }
        else {
            videoV1Subscription?.cancel()
            videoV1Subscription = nil
            videoV1Subscription = TPYTAPIManager
                .ytService
                .getVideoV1(videoId: video.id)
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
                    self?.getM3U8URL(video: video, videoV1: videoV1)
                }
        }
    }
    
    private func getM3U8URL(video: TPYTItemResource, videoV1: TPYTVideoV1) {
        m3u8Subscription = nil
        m3u8Subscription = TPYTAPIManager
            .ytService
            .getStreammingAudioURL(m3u8URL: videoV1.streamingData.hlsManifestUrl)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                eLog("\(error.localizedDescription)")
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.state = .unknown
                    self.playerType = .vlc
                    self.loadCurrentVideo()
                }
            } receiveValue: { m3u8URL in
                var newVideoV1 = videoV1
                newVideoV1.streamingData.setStreamingAudioURL(audioURL: m3u8URL)
                TPStorageManager.shared.saveVideoV1ById(videoId: video.id, videoV1: newVideoV1)
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.state = .unknown
                    self.playerType = .vlc
                    self.loadCurrentVideo()
                }
            }
    }
    
    private func loadCurrentVideo() {
        guard let crVideo = currentVideo else {
            eLog("Current video not found")
            return
        }
        
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
        
        wcCommand.notifyLoadVideo(video: crVideo)
    }
    
    private func cleanPlayer() {
        vlcMediaMetaData = .init()
        playertime = .zero
        reloadVideoTimer?.invalidate()
        reloadVideoTimer = nil
        reloadVideoCount = 0
        timeToNotifyPlayerTime = nil
        
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
    
    func wcNotifyAverageColorOfCurrentVideo(cgColor: CGColor) {
        wcCommand.notifyAverageColorOfCurrentVideo(cgColor: cgColor)
    }
    
    func getGradientColorsFromImage() async -> [Color] {
        guard let video = currentVideo,
              let mainColor = UIImage.getImageCached(from: URLRequest(url: URL(string: video.thumbnails.default.url)!))?.getAverageColor()
        else {
            return [Color(uiColor: .darkGray)]
        }
        
        return [Color(uiColor: mainColor),
                Color(uiColor: mainColor),
                Color(uiColor: .black)]
    }
}

extension TPYTPlayerManager: ITPYTPlayerAction {
    func play() {
        guard let _ = currentVideo else { return }
        
        switch playerType {
        case .vlc:
            vlcPlayer.play()
        case .ytBrowser:
            ytPlayer.playVideo()
        case .undefined:
            return
        }
        
        wcCommand.notifyPlayControl()
    }
    
    func pause() {
        guard let _ = currentVideo else { return }
        
        switch playerType {
        case .vlc:
            vlcPlayer.pause()
        case .ytBrowser:
            ytPlayer.pauseVideo()
        case .undefined:
            return
        }
        
        wcCommand.notifyPauseControl()
        timeToNotifyPlayerTime = nil
    }
    
    func seekToTime(time: Float) {
        guard let _ = currentVideo else { return }
        
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
        guard let _ = currentVideo else { return }
        
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
        guard let _ = currentVideo else { return }
        
        switch playerType {
        case .vlc:
            vlcPlayer.jumpBackward(10)
        case .ytBrowser:
            ytPlayer.seek(toSeconds: max(playertime.time - 10, 0), allowSeekAhead: true)
        case .undefined:
            return
        }
    }
    
    @discardableResult
    func nextSong() -> TPYTItemResource? {
        guard let _ = currentVideo else { return nil }
        guard !playlist.isEmpty else { return nil }
        
        currentIndexVideo += 1
        if currentIndexVideo >= playlist.count, isLoopList {
            currentIndexVideo = 0
        }
        
        let nextVideo = playlist[currentIndexVideo]
        load(video: nextVideo)
        return nextVideo
    }
    
    @discardableResult
    func backSong() -> TPYTItemResource? {
        guard let _ = currentVideo else { return nil }
        guard !playlist.isEmpty else { return nil }
        
        currentIndexVideo -= 1
        if currentIndexVideo < 0, isLoopList {
            currentIndexVideo = playlist.count - 1
        }
        
        let backVideo = playlist[currentIndexVideo]
        load(video: backVideo)
        return backVideo
    }
    
    func closePlayer() {
        isPresented = false
        currentVideo = nil
        timeToNotifyPlayerTime = nil
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        cleanPlayer()
        wcCommand.notifyClosePlayer()
    }
    
    private func handleReachabilityChange(_ connection: Reachability.Connection) {
        iLog("[Reachability.Connection] \(connection)")
        if let latestReachabilityConnection = latestReachabilityConnection,
           latestReachabilityConnection != connection,
           !isNetworkChanged {
            isNetworkChanged = true
        }
        
        latestReachabilityConnection = connection
    }
}

extension TPYTPlayerManager {
    func getStateIcon() -> String {
        if isPlaying {
            return TPPlayerState.playing.getIconPlay()
        }
        
        return state.getIconPlay()
    }
    
    func getMinimizeIconPlay() -> String {
        if isPlaying {
            return TPPlayerState.playing.getMinimizeIconPlay()
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
            self?.state = TPPlayerState.convertState(ytState: state)
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
            self?.playertime = TPPlayerTime(time: 0, duration: duration.rounded())
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
        iLog("\(#function)[Playtime]: \(playTime.rounded())")
        videoPlaytime = playTime
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            self.playertime = TPPlayerTime(time: playTime.rounded(), duration: self.videoDuration)
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayDuration duration: Float) {
        iLog("\(#function)[PlayDuration]: \(duration)")
    }
}

extension TPYTPlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        defer {
            iLog("State changed: \(state)")
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
            if let reloadVideoTime = self.reloadVideoTime {
                iLog("Tryning to reload video at (\(reloadVideoTime.time) - \(reloadVideoTime.duration))")
                vlcPlayer.jumpForward(Int32(max(0, reloadVideoTime.time - 1)))
                playertime = TPPlayerTime(time: reloadVideoTime.time - 1, duration: reloadVideoTime.duration)
                self.reloadVideoTime = nil
            }
            else {
                let playbackDuration = Double(vlcPlayer.media!.length.intValue / 1000)
                if let elapsedPlaybackTime = vlcPlayer.time.value {
                    let playbackTime = elapsedPlaybackTime.doubleValue / 1000
                    iLog("\(playbackTime) - \(playbackDuration)")
                    playertime = TPPlayerTime(time: Float(playbackTime), duration: Float(playbackDuration))
                }
                else {
                    playertime = TPPlayerTime(time: 0, duration: Float(playbackDuration))
                }
            }
            
            return
        case .ended:
            playertime = TPPlayerTime(time: playertime.time + 1, duration: playertime.duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                [unowned self] in
                self.nextSong()
            }
        case .error:
            closePlayer()
            break
        default:
            break
        }
        
        state = TPPlayerState.convertState(vlcState: vlcPlayer.state)
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let media = vlcPlayer.media else { return }
        let playbackDuration = Double(media.length.intValue / 1000)
        if let elapsedPlaybackTime = vlcPlayer.time.value {
            let playbackTime = elapsedPlaybackTime.doubleValue / 1000
            if playertime.time != Float(playbackTime.rounded()) {
                iLog("[VLC PlayerTime] \(playbackTime) - \(playbackDuration)")
                playertime = TPPlayerTime(time: Float(playbackTime.rounded()), duration: Float(playbackDuration))
                notifyPlayerTime(time: playertime)
            }
            
            ///The solution is just temporary because vlckit doesn't support APIs needed.
            ///After 5s if the player doesn't change time, it means that the network was lost or very slow or URL from youtube was closed.
            let hasStreamingAudioURL = currentVideo?.videoV1?.streamingData.hasStreamingAudioURL
            if let hasStreamingAudioURL = hasStreamingAudioURL, !hasStreamingAudioURL {
                startReloadAudio()
            }
        }
    }
    
    private func startReloadAudio() {
        reloadVideoTimer?.invalidate()
        reloadVideoTimer = nil
        
        guard playerType == .vlc else { return }
        
        reloadVideoTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: {
            [weak self] _ in
            guard let self = self else { return }
            guard let currentVideo = self.currentVideo,
                  self.vlcPlayer.state == .buffering,
                  self.vlcPlayer.isPlaying else { return }
            iLog("Trying to reload current video")
            if self.reloadVideoCount == LIMITED_RELOADING_VIDEO {
                self.reloadVideoCount = 0
                self.nextSong()
            }
            else {
                self.reloadVideoCount += 1
                self.reloadVideoTime = self.playertime
                self.load(video: currentVideo, isReloading: true)
            }
        })
    }
    
    private func notifyPlayerTime(time: TPPlayerTime) {
        guard let mTimeToNotifyPlayerTime = timeToNotifyPlayerTime else {
            timeToNotifyPlayerTime = .now
            wcCommand.notifyPlayerTime(time: time)
            return
        }
        
        guard Date.now.timeIntervalSince1970 - mTimeToNotifyPlayerTime.timeIntervalSince1970 > 30 else {
            return
        }
        
        timeToNotifyPlayerTime = .now
        wcCommand.notifyPlayerTime(time: time)
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
