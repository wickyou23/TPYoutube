//
//  AWTPPlayerVide.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import SwiftUI

struct AWTPPlayerView: View {
    @StateObject private var player = AWTPPlayerManager.shared
    @StateObject private var vm = AWTPPlayerViewModel()
    
    private var disableColor: Color {
        player.isLoadingDetails ? .gray : .white
    }
    
    private var titleVideo: String {
        return player.video?.title ?? "TPYoutube"
    }
    
    private var subTitleVideo: String {
        return player.video?.channelTitle ?? "..."
    }
    
    private var screenSize = WKInterfaceDevice.current().screenBounds
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(titleVideo)
                .lineLimit(1)
                .appFont(13)
            
            Text(subTitleVideo)
                .lineLimit(1)
                .foregroundColor(.gray)
                .appFont(11)
            
            Spacer()
                .frame(height: 10)
            
            RoundedRectangle(cornerRadius: 2)
                .frame(height: 2)
            
            Spacer()
                .frame(height: 16)
            
            HStack {
                Button {
                    player.backControl()
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(width: 30, height: 30)
                        .foregroundColor(disableColor)
                }
                .tint(.clear)
                .disabled(player.isLoadingDetails)
                
                if player.isLoadingDetails && player.video != nil {
                    ProgressView()
                        .frame(width: 70, height: 70)
                        .padding()
                }
                else {
                    Button {
                        if player.state != .playing {
                            player.playControl()
                        }
                        else {
                            player.pauseControl()
                        }
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable(resizingMode: .stretch)
                            .frame(width: 70, height: 70)
                            .foregroundColor(disableColor)
                    }
                    .tint(.clear)
                    .disabled(player.isLoadingDetails)
                }
                
                Button {
                    player.nextControl()
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: 30, height: 30)
                        .foregroundColor(disableColor)
                }
                .tint(.clear)
                .disabled(player.isLoadingDetails)
            }
            .shadow(color: player.averageColorOfCurrentVideo, radius: 10)
        }
        .padding()
        .background(
            Circle()
                .fill(
                    RadialGradient(gradient: Gradient(colors: [player.averageColorOfCurrentVideo, .black]),
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 75)
                )
                .position(x: screenSize.width / 2,
                          y: screenSize.height / 2 - 12)
                .scaleEffect(1.2)
        )
    }
}

struct AWTPPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        AWTPPlayerView()
            .environmentObject(TPTheme.shared)
    }
}
