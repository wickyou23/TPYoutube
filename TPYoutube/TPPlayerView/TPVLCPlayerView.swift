//
//  TPYTAudioPlayerView.swift
//  TPYoutube
//
//  Created by Thang Phung on 14/03/2023.
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit
import MediaPlayer
import MobileVLCKit
import UIKit

struct TPYTPlayerAudioView: View {
    let video: TPYTItemResource
    
//    @StateObject var vm = TPYTPlayerAudioViewModel()
    
    @State var play: Bool = false
    
    let testURL =
    """
    https://rr2---sn-vgqsknls.googlevideo.com/videoplayback?expire=1678957846&ei=togSZLPFC9HdgwPH9oSYDg&ip=54.86.50.139&id=o-AKjwqT4PfYktjL8wSSUPULZ6XoybAxGx4jPnuQvUMnvl&itag=140&source=youtube&requiressl=yes&mh=9y&mm=31%2C26&mn=sn-vgqsknls%2Csn-ab5sznzl&ms=au%2Conr&mv=u&mvi=2&pl=23&vprv=1&svpuc=1&mime=audio%2Fmp4&gir=yes&clen=175083842&dur=10818.362&lmt=1678786966647082&mt=1678935381&fvip=3&keepalive=yes&fexp=24007246&c=IOS&txp=6318224&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Csvpuc%2Cmime%2Cgir%2Cclen%2Cdur%2Clmt&sig=AOq0QJ8wRQIhAMa7tDGhpIseucVkGF5s5X_DtKncHpQdzM2tTde7t0xvAiAx2pjk8LMLCYI_fLVsaCan1VT7LTi297d-byRRCCBeSw%3D%3D&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl&lsig=AG3C_xAwRAIgEWvSdGFRcuWIa-PeBybZtrWcRzhQR4Q3XXoM5p4RgasCIAZ_glSokfPoWl1RWNEBI3E5GGncU14IVeLyAFaYhML3
    """
    
    var body: some View {
        VStack {
//            VideoPlayer(player: vm.player)
            
//            TPVLCAudiolaybackSwiftUIView(mediaURL: testURL, play: $play)
            
            Button {
//                vm.playTestVideo()
                play.toggle()
            } label: {
                Text("Touch me")
            }
        }
    }
}

struct TPVLCPlayerView: UIViewRepresentable {
    @EnvironmentObject private var player: TPYTPlayerManager
    
    func makeUIView(context: Context) -> TPVLCPAudiolaybackView {
        return player.vlcPlayerUIView
    }
    
    func updateUIView(_ uiView: TPVLCPAudiolaybackView, context: Context) {}
    
    func makeCoordinator() -> () {}
}

class TPVLCPAudiolaybackView: UIView {
    let vlcPlayer = VLCMediaPlayer()
    
    private let mediaMetaData: TPVLCMetaData = TPVLCMetaData()
    private var videoView: UIView!
    
    override init(frame: CGRect) {
        self.videoView = UIView(frame: .zero)
        self.videoView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        addSubview(videoView)

        videoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        videoView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0).isActive = true
        videoView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: 0).isActive = true
        videoView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        videoView.backgroundColor = .black
        
        vlcPlayer.drawable = videoView
        
        //Setup logger
        let consoleLogger = VLCConsoleLogger()
        consoleLogger.level = .debug
        vlcPlayer.libraryInstance.loggers = [consoleLogger]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//extension TPVLCPAudiolaybackView: VLCMediaPlayerDelegate {
//    func mediaPlayerStateChanged(_ aNotification: Notification) {
//        let currentState = vlcPlayer.state
//        switch currentState {
//        case .buffering:
//            vlcPlayer.media?.delegate = self
//        default:
//            break;
//        }
//
//        mediaMetaData.updateMetadataFromMedia(video: TPYTSearchViewModel().getDumpVideos().first!,
//                                              mediaPlayer: vlcPlayer)
//    }
//}
//
//extension TPVLCPAudiolaybackView: VLCMediaDelegate {
//    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
//        mediaMetaData.updateMetadataFromMedia(video: TPYTSearchViewModel().getDumpVideos().first!,
//                                              mediaPlayer: vlcPlayer)
//    }
//}



//class TPYTPlayerAudioViewModel: NSObject, ObservableObject {
//    @Published var player: AVPlayer?
//
//    private var _localPlayer: AVPlayer?
//
//    override init() {
//        super.init()
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(self.handleDidEnterBackground(_:)),
//                                               name: UIApplication.didEnterBackgroundNotification,
//                                               object: nil)
//
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(self.handleWillEnterForegroundNotification(_:)),
//                                               name: UIApplication.willEnterForegroundNotification,
//                                               object: nil)
//    }
//
//    func playTestVideo() {
//        let testURL =
//        """
//        https://rr4---sn-vgqsrne6.googlevideo.com/videoplayback?expire=1678899088&ei=MKMRZM7mDI7n8wT_wYyIAw&ip=54.86.50.139&id=o-AMxVv2sOxfJon0GA6s6DIIcrWScR61LTWjC1Eg6rQUrX&itag=140&source=youtube&requiressl=yes&mh=gu&mm=31%2C26&mn=sn-vgqsrne6%2Csn-ab5l6nrs&ms=au%2Conr&mv=u&mvi=4&pl=23&spc=H3gIhu6g09_wddBOrOOz3fXYRgQiJSCSX0Opf2_qI0sIRcllCg&vprv=1&mime=audio%2Fmp4&ns=5VPOPFFkldrwUySDQXbPZIEL&gir=yes&clen=9504765&dur=587.255&lmt=1663519740165335&mt=1678877184&fvip=5&keepalive=yes&fexp=24007246&c=WEB&txp=5432434&n=c7iA4tEor1WO8AEtWV&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cspc%2Cvprv%2Cmime%2Cns%2Cgir%2Cclen%2Cdur%2Clmt&sig=AOq0QJ8wRAIgdtnRwW_JLuutXQelEoiyNI8ozsoMAwQcW7hACySFGZ0CIHyf3k7h7xK1g7JVT2vtLLxPCGAR5ETt1zlQaSWteHmD&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl&lsig=AG3C_xAwRQIgBOGoW8bWJlRTfNBUDo7yLOnJA848qUZCRgSRFpDUnT8CIQCrcbsVxcqiMAekGH7R6WAIR6oCIM_OQFTzf5L49oeHUw%3D%3D
//        """
//
//        let url = URL(string: testURL)!
//        let asset = AVURLAsset(url: url)
//        let item = AVPlayerItem(asset: asset)
//
//        _localPlayer = AVPlayer(playerItem: item)
//        _localPlayer?.playImmediately(atRate: 1.0)
//
//        player = _localPlayer
//
//        do {
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {}
//    }
//
//    private func setupRemoteTransportControls() {
//        // Get the shared MPRemoteCommandCenter
//        let commandCenter = MPRemoteCommandCenter.shared()
//
//        // Add handler for Play Command
//        commandCenter.playCommand.isEnabled = true
//        commandCenter.playCommand.addTarget { [unowned self] event in
//            if _localPlayer?.rate == 0.0 {
//                _localPlayer?.play()
//                return .success
//            }
//            return .commandFailed
//        }
//
//        // Add handler for Pause Command
//        commandCenter.pauseCommand.addTarget { [unowned self] event in
//            if _localPlayer?.rate == 1.0 {
//                _localPlayer?.pause()
//                return .success
//            }
//            return .commandFailed
//        }
//    }
//
//
//    @objc func handleDidEnterBackground(_ nofification: Notification) {
//        player = nil
//        DispatchQueue.main.async {
//            [weak self] in
//            self?.setupRemoteTransportControls()
//        }
//    }
//
//    @objc func handleWillEnterForegroundNotification(_ nofification: Notification) {
//        player = _localPlayer
//    }
//}
 
struct TPYTPlayerAudioView_Previews: PreviewProvider {
    static var previews: some View {
        TPYTPlayerAudioView(video: TPYTSearchViewModel().getDumpVideos().first!)
    }
}
