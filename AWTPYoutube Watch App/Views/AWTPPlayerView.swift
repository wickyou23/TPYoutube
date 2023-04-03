//
//  AWTPPlayerVide.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import SwiftUI

struct AWTPPlayerView: View {
    @EnvironmentObject private var theme: TPTheme
    @ObservedObject private var vm: AWTPPlayerViewModel
    
    init(video: TPYTItemResource) {
        vm = AWTPPlayerViewModel(video: video)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(vm.video.title)
                .lineLimit(1)
                .appFont(13)
            
            Text(vm.video.channelTitle)
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
                    vm.preVideo()
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                .tint(.clear)
                
                if vm.state == .loading {
                    ProgressView()
                        .frame(width: 70, height: 70)
                        .padding()
                }
                else {
                    Button {
                        if vm.state == .pause {
                            vm.playVideo()
                        }
                        else {
                            vm.pauseVideo()
                        }
                    } label: {
                        Image(systemName: vm.state == .play ? "pause.circle.fill" : "play.circle.fill")
                            .resizable(resizingMode: .stretch)
                            .frame(width: 70, height: 70)
                            .foregroundColor(.white)
                    }
                    .tint(.clear)
                }
                
                
                Button {
                    vm.nextVideo()
                } label: {
                    Image(systemName: "forward.fill")
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                }
                .tint(.clear)
            }
        }
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AWTPPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        AWTPPlayerView(video: TPDummyDatas().getDumpVideos().first!)
    }
}
