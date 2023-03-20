//
//  TPPlayerViewModifier.swift
//  TPYoutube
//
//  Created by Thang Phung on 07/03/2023.
//

import Foundation
import SwiftUI
import Combine
import CachedAsyncImage

struct TPPlayerViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                TPMainPlayerView()
                    .environmentObject(TPYTPlayerManager.shared)
            )
    }
}

fileprivate struct TPMainPlayerView: View {
    @EnvironmentObject private var player: TPYTPlayerManager
    @EnvironmentObject private var theme: TPTheme
    @EnvironmentObject private var appVM: AppViewModel
    
    @State private var isMinimize: Bool = false
    @State private var isRotating: Double = 0
    @State private var mainPlayerPosition: CGRect = .zero
    @State private var titleHtml: AttributedString?
    @State private var tabbarBottom: CGFloat?
    
    private let sizeImage = UIScreen.main.bounds.width * 0.75
    private let screenSize = UIScreen.main.bounds
    private let minimizeSize: CGFloat = 65
    private let minimizeScale: CGFloat = 0.15
    private var discScale: CGFloat {
        isMinimize ? minimizeScale : 1
    }
    
    private var discScalePosition: CGPoint {
        isMinimize ? CGPoint(x: (sizeImage * minimizeScale) / 2 + 8, y: minimizeSize / 2) : CGPoint(x: screenSize.width / 2, y: mainPlayerPosition.origin.y + (sizeImage / 2))
    }
    
    var video: TPYTItemResource {
        player.currentVideo!
    }
    
    var body: some View {
        GeometryReader { geo in
            if player.isPresented {
                VStack {
                    Spacer()
                    getContentPlayerView()
                }
                .clipped()
                .shadow(radius: 5, y: -3)
                .ignoresSafeArea(.keyboard)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: isMinimize ? (tabbarBottom ?? geo.safeAreaInsets.bottom) + 49 : 0, trailing: 0))
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.2), value: isMinimize)
                .onAppear {
                    tabbarBottom = UIApplication.shared.tpKeyWindow?.safeAreaInsets.bottom
                }
            }
        }
        .animation(.spring(response: 0.4), value: player.isPresented)
        .frame(width: screenSize.size.width, height: screenSize.size.height, alignment: .bottom)
        .ignoresSafeArea()
        .padding(.zero)
        .onChange(of: player.currentVideo, perform: { newValue in
            if let _ = newValue, player.isPresented {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.35) {
                    titleHtml = video.title.decodeStringToHTMLAttribute(uiFont: theme.appUIFont(.body, weight: .medium), color: .white)
                }
            }
        })
    }
    
    @ViewBuilder private func getContentPlayerView() -> some View {
        ZStack {
            ZStack {
                if !isMinimize {
                    getMainPlayer()
                        .zIndex(0)
                        .background(
                            GeometryReader(content: {
                                mainPlayerGeo in
                                Color.clear
                                    .onAppear {
                                        let frame = mainPlayerGeo.frame(in: CoordinateSpace.global)
                                        mainPlayerPosition = frame
                                    }
                            })
                        )
                }
                else {
                    getMinimizePlayer()
                        .zIndex(0)
                }
                
                getDiscView()
                    .scaleEffect(x: discScale, y: discScale)
                    .position(x: discScalePosition.x, y: discScalePosition.y)
                    .zIndex(1)
            }
            .frame(width: screenSize.width, alignment: .leading)
            
            if !isMinimize {
                HStack {
                    Button {
                        isMinimize.toggle()
                    } label: {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    .tint(.white)
                    .frame(width: 30, height: 30)
                    
                    Spacer()
                    
                    Button {
                        player.isPresented.toggle()
                        player.cleanPlayer()
                        player.currentVideo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                    }
                    .tint(.white)
                    .frame(width: 30, height: 30)
                }
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .position(x: screenSize.width / 2,
                          y: (UIApplication.shared.tpKeyWindow?.safeAreaInsets.top ?? 0) + 8)
            }
        }
        .frame(width: screenSize.size.width, height: isMinimize ? minimizeSize : screenSize.size.height, alignment: .bottom)
        .clipped()
        .background(Color(uiColor: UIColor.darkGray))
    }
    
    @ViewBuilder private func getMainPlayer() -> some View {
        VStack {
            Spacer()
                .frame(width: sizeImage, height: sizeImage)
            
            Spacer()
                .frame(height: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                if titleHtml == nil {
                    Text(video.title)
                        .transition(.opacity)
                        .foregroundColor(.white)
                        .appFontWeight(.medium)
                        .lineLimit(2)
                }
                else {
                    Text(titleHtml!)
                        .transition(.opacity)
                        .lineLimit(2)
                }
                
                Text(video.channelTitle)
                    .foregroundColor(.gray)
                    .appFont()
                
            }
            .animation(.linear, value: titleHtml)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
                .frame(height: 8)
            
            TPPlayerSliderView {
                value in
                player.seekToTime(time: value)
            }
            .frame(height: 50)
            
            Spacer()
                .frame(height: 40)
            
            TPPlayerControllerView()
            
            Spacer()
                .frame(height: 40)
            
            TPVolumeSliderView()
                .frame(width: screenSize.size.width * 0.7)
        }
        .padding()
    }
    
    @ViewBuilder private func getMinimizePlayer() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 8, content: {
                Spacer()
                    .frame(width: sizeImage * minimizeScale)
                
                VStack(alignment: .leading, spacing: 5) {
                    if titleHtml == nil {
                        Text(video.title)
                            .foregroundColor(.white)
                            .appFontWeight(.medium)
                            .lineLimit(1)
                    }
                    else {
                        TPMarqueeText(
                            text: titleHtml!,
                            startAnimation: player.isPlaying,
                            startDelay: 3
                        )
                        .id("TPMarqueeText")
                    }
                    
                    Text(video.channelTitle)
                        .foregroundColor(.gray)
                        .appFont()
                }
                
                Spacer()
                
                Button {
                    if player.isPlaying {
                        player.pause()
                    }
                    else {
                        player.play()
                    }
                } label: {
                    Image(systemName: player.getMinimizeIconPlay())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                .tint(.white)
                .disabled(!player.isPlayerReady)
                .frame(width: 35, height: 30)

            })
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8))
            
            VStack {
                Spacer()
                theme.appColor
                    .frame(width: screenSize.width * CGFloat(player.playertime.time / max(player.playertime.duration, 1)),
                           height: 3)
            }
        }
        .onTapGesture {
            isMinimize.toggle()
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder private func getDiscView() -> some View {
        ZStack {
            VStack {
                TPYTPlayerView()
            }
            .frame(width: 10, height: 10)
            
            CachedAsyncImage(url: URL(string: video.thumbnails.high.url), transaction: .init(animation: Animation.easeInOut(duration: 0.2))) {
                phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    CachedAsyncImage(url: URL(string: video.thumbnails.default.url)!, content: {
                        smallPhase in
                        switch smallPhase {
                        case .success(let smallImage):
                            smallImage
                                .resizable()
                        default:
                            ProgressView()
                                .background(Color.black)
                        }
                    })
                }
            }
            .frame(width: sizeImage, height: sizeImage)
            .cornerRadius(sizeImage / 2)
            
            Circle()
                .fill(Color(uiColor: UIColor.darkGray))
                .frame(width: 80, height: 80)
            
            Circle()
                .fill(.white)
                .frame(width: 20, height: 20)
        }
        .shadow(color: .black, radius: 10)
        .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
        .animation(Animation.linear(duration: 10).speed(0.1).repeatForever(autoreverses: false), value: player.isPlaying)
    }
}

struct TPPlayerViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
    
    struct Preview: View {
        @State var isPresented = false
        @StateObject var playerManager = TPYTPlayerManager.shared
        
        var body: some View {
            GeometryReader { geo in
                ZStack {
                    Color.clear
                    VStack {
                        Button("Toggle", action: {
                            isPresented.toggle()
                        })
                        Spacer()
                    }
                }
                .modifier(TPPlayerViewModifier())
                .environmentObject(TPTheme.shared)
                .environmentObject(TPYTPlayerManager.shared)
                .environmentObject(AppViewModel())
            }
            .onAppear {
                DispatchQueue.main.async {
                    playerManager.load(video: TPYTSearchViewModel().getDumpVideos().first!)
                }
            }
        }
    }
}
