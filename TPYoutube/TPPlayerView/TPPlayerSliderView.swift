//
//  TPMusicSlider.swift
//  TPYoutube
//
//  Created by Thang Phung on 28/02/2023.
//

import Foundation
import SwiftUI

struct TPPlayerSliderView: View {
    @EnvironmentObject private var player: TPYTPlayerManager
//    @Binding var playerTime: TPYTPlayerTime
    
    var onSliderChange: ((Float) -> Void)
    
    @State private var isSliderDragging: Bool = false
    @State private var sliderValue: Float = 0
    
    private var sliderHeight: CGFloat {
        return isSliderDragging ? 16 : 8
    }
    
    private var sliderFont: Font {
        return isSliderDragging ? TPTheme.shared.appFont(14, weight: .medium) : TPTheme.shared.appFont(12, weight: .regular)
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
//                TPSlider(value: $sliderValue, minValue: 0, maxValue: playerTime.duration) {
//                    dragValue in
//                    if !isSliderDragging {
//                        withAnimation(Animation.easeInOut(duration: 0.2)) {
//                            isSliderDragging = true
//                        }
//                    }
//                } onEnded: {
//                    endedValue in
//                    onSliderChange(endedValue)
//                    playerTime = TPYTPlayerTime(time: endedValue, duration: playerTime.duration)
//
//                    withAnimation(Animation.easeInOut(duration: 0.2)) {
//                        isSliderDragging = false
//                    }
//                }
//                .frame(height: sliderHeight)
//                .onChange(of: playerTime, perform: {
//                    newValue in
//                    sliderValue = newValue.time
//                })
//                .onAppear {
//                    sliderValue = playerTime.time
//                }
                
                TPSlider(value: $sliderValue, minValue: 0, maxValue: player.playertime.duration) {
                    dragValue in
                    if !isSliderDragging {
                        withAnimation(Animation.easeInOut(duration: 0.2)) {
                            isSliderDragging = true
                        }
                    }
                } onEnded: {
                    endedValue in
                    onSliderChange(endedValue)
                    player.playertime = TPYTPlayerTime(time: endedValue, duration: player.playertime.duration)
                    
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        isSliderDragging = false
                    }
                }
                .frame(height: sliderHeight)
                .onChange(of: player.playertime, perform: {
                    newValue in
                    sliderValue = newValue.time
                })
                .onAppear {
                    sliderValue = player.playertime.time
                }
                
                Spacer()
                    .frame(height: 8)
                
                HStack {
                    Text(getLeftTime(geo))
                        .font(sliderFont)
                        .foregroundColor(.white)
                    Spacer()
                    Text(getRightTime(geo))
                        .font(sliderFont)
                        .foregroundColor(.white)
                }
            }
            .frame(height: geo.size.height)
        }
    }
    
    private func getLeftTime(_ geo: GeometryProxy) -> String {
//        var duration = playerTime.time
//        if isSliderDragging {
//            duration = sliderValue
//        }
//
//        return duration.convertDurationToTime()
        
        var duration = player.playertime.time
        if isSliderDragging {
            duration = sliderValue
        }
        
        return duration.convertDurationToTime()
    }
    
    private func getRightTime(_ geo: GeometryProxy) -> String {
//        var duration = playerTime.duration - playerTime.time
//        if isSliderDragging {
//            duration = playerTime.duration - sliderValue
//        }
//
//        return ((duration > 0) ? "-" : "") + duration.convertDurationToTime()
        
        var duration = player.playertime.duration - player.playertime.time
        if isSliderDragging {
            duration = player.playertime.duration - sliderValue
        }
        
        return ((duration > 0) ? "-" : "") + duration.convertDurationToTime()
    }
}

struct TPPlayerSliderView_Previews: PreviewProvider {
    static var previews: some View {
//        TPPlayerSliderView(playerTime: .constant(TPYTPlayerTime(time: 100, duration: 180)), onSliderChange: {
//            value in
//
//        })
//        .background(Color(uiColor: UIColor.darkGray))
//        .padding()
        
        TPPlayerSliderView(onSliderChange: {
            value in
            
        })
        .background(Color(uiColor: UIColor.darkGray))
        .padding()
        .environmentObject(TPYTPlayerManager.shared)
    }
}

fileprivate extension Float {
    func convertDurationToTime() -> String {
        let s = Int(self.truncatingRemainder(dividingBy: 60).rounded(.down))
        var m = Int((self / 60).rounded(.down))
        var h = 0
        if m >= 60 {
            h = Int((Float(m) / 60).rounded(.down))
            m = Int(Float(m).truncatingRemainder(dividingBy: 60).rounded(.down))
        }
        
        let formater = NumberFormatter()
        formater.maximumIntegerDigits = 2
        
        if h > 0 {
            return "\(formater.string(for: h)!):\(formater.string(for: m)!):\(NSString(format: "%02d", s))"
        }
        else {
            return "\(formater.string(for: m)!):\(NSString(format: "%02d", s))"
        }
    }
}
