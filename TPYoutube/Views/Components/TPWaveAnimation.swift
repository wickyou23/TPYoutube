//
//  TPWaveAnimation.swift
//  TPYoutube
//
//  Created by Thang Phung on 10/03/2023.
//

import Foundation
import SwiftUI

struct TPWaveAnimation: View {
    @EnvironmentObject private var theme: TPTheme
    
    @State private var waveAnimation1: Bool = false
    @State private var waveAnimation2: Bool = false
    @State private var waveAnimation3: Bool = false
    @State private var startAnimation: Bool = false
    
    private let animation: Animation = .linear(duration: 0.8).repeatForever()
    private let nullAnimation: Animation = .linear(duration: 0)
    
    var body: some View {
        if startAnimation {
            DispatchQueue.main.async {
                waveAnimation1 = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.6) {
                waveAnimation2 = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                waveAnimation3 = true
            }
        }
        else {
            DispatchQueue.main.async {
                waveAnimation1 = false
                waveAnimation2 = false
                waveAnimation3 = false
            }
        }
        
        return GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 1) {
                theme.appColor
                    .animation(waveAnimation1 ? animation : nullAnimation, value: waveAnimation1)
                    .frame(width: 5, height: waveAnimation1 ? geo.size.height : 5)
                theme.appColor
                    .animation(waveAnimation2 ? animation : nullAnimation, value: waveAnimation2)
                    .frame(width: 5, height: waveAnimation2 ? geo.size.height : 5)
                theme.appColor
                    .animation(waveAnimation3 ? animation : nullAnimation, value: waveAnimation3)
                    .frame(width: 5, height: waveAnimation3 ? geo.size.height : 5)
            }
            .frame(height: geo.size.height, alignment: .bottom)
        }
        .frame(width: 17)
        .onReceive(TPYTPlayerManager.shared.$state, perform: { _ in
            let isPlaying = TPYTPlayerManager.shared.isPlaying
            if isPlaying != startAnimation {
                startAnimation = isPlaying
            }
        })
    }
}

struct TPWaveAnimation_Previews: PreviewProvider {
    static var previews: some View {
        TPWaveAnimation()
            .frame(height: 20)
            .background(.black)
            .environmentObject(TPTheme.shared)
    }
}
