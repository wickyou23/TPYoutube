//
//  TPPlayerControllerView.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation
import SwiftUI

struct TPPlayerControllerView: View {
    @EnvironmentObject private var player: TPYTPlayerManager
    
    var disableColor: Color {
        return (player.isPlayerReady) ? .white : .white.opacity(0.5)
    }
    
    var body: some View {
        HStack(spacing: 40) {
            Button {
                if player.isPlaylist {
                    player.backSong()
                }
                else {
                    if player.isPlaying {
                        player.next10()
                    }
                }
            } label: {
                Image(systemName: player.isPlaylist ? "backward.fill" : "gobackward.10")
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(disableColor)
            }
            .tint(.white)
            
            if player.isPlayerReady {
                Button {
                    if player.isPlaying {
                        player.pause()
                    }
                    else {
                        player.play()
                    }
                } label: {
                    Image(systemName: player.getStateIcon())
                        .resizable(resizingMode: .stretch)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                }
                .tint(.white)
            }
            else {
                ProgressView()
                    .frame(width: 70, height: 70)
                    .background(.white)
                    .cornerRadius(35)
            }
            
            Button {
                if player.isPlaylist {
                    player.nextSong()
                }
                else {
                    if player.isPlaying {
                        player.next10()
                    }
                }
            } label: {
                Image(systemName: player.isPlaylist ? "forward.fill" : "goforward.10")
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(disableColor)
            }
            .tint(.white)
        }
    }
}

struct TPPlayerControllerView_Previews: PreviewProvider {
    static var previews: some View {
        TPPlayerControllerView()
            .environmentObject(TPYTPlayerManager.shared)
            .background(Color(uiColor: UIColor.darkGray))
            .padding()
            
    }
}
