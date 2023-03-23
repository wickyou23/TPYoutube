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

protocol TPVLCPAudiolaybackViewDelegate: AnyObject {
    func mediaPlayerMediaChanged(newMedia: VLCMedia)
}

class TPVLCPAudiolaybackView: UIView {
    let vlcPlayer = VLCMediaPlayer()
    
    private let mediaMetaData: TPVLCMetaData = TPVLCMetaData()
    private var videoView: UIView!
    
    weak var delegate: TPVLCPAudiolaybackViewDelegate?
    
    deinit {
        iLog("TPVLCPAudiolaybackView deinit =====")
        vlcPlayer.removeObserver(self, forKeyPath: "media")
    }
    
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
        
        vlcPlayer.addObserver(self, forKeyPath: "media", options: .new, context: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "media" {
            guard let newMedia = change?[.newKey] as? VLCMedia else {
                return
            }
            
            self.delegate?.mediaPlayerMediaChanged(newMedia: newMedia)
        }
    }
}

struct TPYTPlayerAudioView_Previews: PreviewProvider {
    static var previews: some View {
        TPYTPlayerAudioView(video: TPYTSearchViewModel().getDumpVideos().first!)
    }
}
