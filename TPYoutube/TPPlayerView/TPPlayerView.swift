//
//  TPPlayer.swift
//  TPYoutube
//
//  Created by Thang Phung on 23/02/2023.
//

import Foundation
import SwiftUI
import YouTubeiOSPlayerHelper
import CachedAsyncImage

struct TPPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var player: TPYTPlayerManager
    
    let video: TPYTItemResource
    
    ///Another way
//    let playerReference = ViewReference<YTPlayerView>()

    private let sizeImage = UIScreen.main.bounds.width * 0.8
    
    @State private var isRotating: Double = 0
//    @State private var playerTime: TPYTPlayerTime = TPYTPlayerTime(time: 0, duration: 0)
//    @State private var playerState: TPYTPlayerViewState = .unknown
//    @State private var playerAction: TPYTPlayerViewAction = .noAction
    
    var isPlayerReady: Bool {
//        return (playerState != .unknown && playerState != .buffering)
        
        return player.isPlayerReady
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    ZStack {
                        VStack {
//                            TPYTPlayerView(video: video,
//                                           stateChanged: player.playerState,
//                                           playertimeChanged: player.playerTime,
//                                           action: player.playerAction)
                            
                            TPYTPlayerView()
                        }
                        .frame(width: 10, height: 10)
                        
                        CachedAsyncImage(url: URL(string: video.thumbnails.medium.url), transaction: .init(animation: Animation.easeInOut(duration: 0.2))) {
                            phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: sizeImage, height: sizeImage)
                                    .cornerRadius(sizeImage / 2)
                            default:
                                CachedAsyncImage(url: URL(string: video.thumbnails.default.url)!, content: {
                                    smallPhase in
                                    switch smallPhase {
                                    case .success(let smallImage):
                                        smallImage
                                            .resizable()
                                            .frame(width: sizeImage, height: sizeImage)
                                            .cornerRadius(sizeImage / 2)
                                    default:
                                        ProgressView()
                                            .background(Color.black)
                                            .frame(width: sizeImage, height: sizeImage)
                                            .cornerRadius(sizeImage / 2)
                                    }
                                })
                            }
                        }
                        
                        Circle()
                            .fill(Color(uiColor: UIColor.darkGray))
                            .frame(width: 80, height: 80)
                        
                        ///Another way
//                        TPYTPlayerView(video: video, viewReference: playerReference, stateChanged: $playerState)
//                            .frame(width: 10, height: 10)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                    }
                    .shadow(color: .black, radius: 10)
                    .rotationEffect(.degrees(isRotating))
                    .animation(Animation.linear(duration: 10) .speed(0.1).repeatForever(autoreverses: false), value: isRotating)
                    .onAppear {
                        isRotating = 360
                    }
                    
                    Spacer()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(video.title)
                            .foregroundColor(.white)
                            .appFontWeight(.medium)
                            .lineLimit(2)
                        Text(video.channelTitle)
                            .foregroundColor(.gray)
                            .appFont()
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                        .frame(height: 8)
                    
//                    TPPlayerSliderView(playerTime: $playerTime) {
//                        value in
//                        playerAction = .seek(value)
//                    }
//                    .frame(height: 50)
                    
//                    TPPlayerSliderView(playerTime: $player.playertime) {
//                        value in
//                        player.seekToTime(time: value)
//                    }
//                    .frame(height: 50)
                    
                    TPPlayerSliderView {
                        value in
                        player.seekToTime(time: value)
                    }
                    .frame(height: 50)
                    
                    Spacer()
                        .frame(height: 40)
                    
//                    TPPlayerControllerView(playerState: $playerState, playerAction: $playerAction)
                    
                    TPPlayerControllerView()
                    
                    Spacer()
                        .frame(height: 40)
                    
                    TPVolumeSliderView()
                        .frame(width: geo.size.width * 0.7)
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .tint(.white)
                .offset(x: (UIScreen.main.bounds.width / 2) - 20,
                        y: -(UIScreen.main.bounds.height / 2) + geo.safeAreaInsets.top + 10)
            }
            .padding()
            .frame(height: geo.size.height)
            .background(Color(uiColor: UIColor.darkGray))
        }
        .disabled(!isPlayerReady)
    }
}

struct TPPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        TPPlayerView(video: TPYTSearchViewModel().getDumpVideos().first!)
            .environmentObject(TPYTPlayerManager.shared)
    }
}
