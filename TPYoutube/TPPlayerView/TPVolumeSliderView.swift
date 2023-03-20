//
//  TPVolumeSlider.swift
//  TPYoutube
//
//  Created by Thang Phung on 28/02/2023.
//

import Foundation
import SwiftUI
import MediaPlayer

struct TPVolumeSliderView: View {
    @State private var volumeValue: Float = 0
    @State private var volumeAction: TPMPVolumeViewAction = .noAction
    @State private var isSliderDragging: Bool = false
    @State private var sliderValue: Float = 0
    
    private var sliderHeight: CGFloat {
        return isSliderDragging ? 12 : 6
    }
    
    private var sliderFont: Font {
        return isSliderDragging ? .system(size: 14, weight: .medium) : .system(size: 12, weight: .regular)
    }
    
    private var iconColor: Color {
        return isSliderDragging ? .white : .gray
    }
    
    var body: some View {
        VStack(spacing: 0)  {
            HStack (spacing: 10) {
                Image(systemName: "speaker.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(iconColor)
                    .frame(width: 16, height: 16)
                
                TPSlider(value: $volumeValue, minValue: 0, maxValue: 1) {
                    dragValue in
                    if !isSliderDragging {
                        withAnimation(Animation.easeInOut(duration: 0.2)) {
                            isSliderDragging = true
                        }
                    }
                } onEnded: {
                    endedValue in
                    volumeAction = .change(endedValue)
                    withAnimation(Animation.easeInOut(duration: 0.2)) {
                        isSliderDragging = false
                    }
                }
                .frame(height: sliderHeight)
                
                Image(systemName: "speaker.wave.3.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
            }
            
            TPMPVolumeView(volumeValue: $volumeValue, volumeAction: $volumeAction)
                .frame(width: 1, height: 1)
                .hidden()
        }
    }
}

struct TPVolumeSliderView_Previews: PreviewProvider {
    static var previews: some View {
        TPVolumeSliderView()
        .background(Color(uiColor: UIColor.darkGray))
        .padding()
    }
}

enum TPMPVolumeViewAction {
    case change(Float), noAction
}

struct TPMPVolumeView: UIViewRepresentable {
    typealias UIViewType = MPVolumeView
    
    @Binding var volumeValue: Float
    @Binding var volumeAction: TPMPVolumeViewAction
    
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView()
        context.coordinator.systemVolumeSlider = view.subviews.first(where: { $0 is UISlider }) as? UISlider
        return view
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        switch volumeAction {
        case .change(let newVolume):
            context.coordinator.setVolumeValue(volume: newVolume)
        case .noAction:
            return
        }
        
        DispatchQueue.main.async {
            volumeAction = .noAction
        }
    }
    
    func makeCoordinator() -> TPMPVolumeViewCoordinator {
        TPMPVolumeViewCoordinator(volumeValue: $volumeValue)
    }
}

class TPMPVolumeViewCoordinator: NSObject {
    var volumeValue: Binding<Float>

    init(volumeValue: Binding<Float>) {
        self.volumeValue = volumeValue
        super.init()
    }

    var systemVolumeSlider: UISlider? {
        didSet {
            self.systemVolumeSlider?.addTarget(self, action: #selector(volumeDidChange), for: .valueChanged)
        }
    }
    
    @objc func volumeDidChange() {
        iLog("Phys volume has changed: \(self.systemVolumeSlider!.value)")
        self.volumeValue.wrappedValue = self.systemVolumeSlider!.value
    }
    
    func setVolumeValue(volume: Float) {
        iLog("Volume changed to: \(volume)")
        self.systemVolumeSlider?.value = volume
        DispatchQueue.main.async {
            [weak self] in
            self?.volumeValue.wrappedValue = volume
        }
        
    }
}
