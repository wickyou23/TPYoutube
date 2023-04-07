//
//  AWTPPlayerViewProgressBarViewModel.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 06/04/2023.
//

import Foundation
import Combine

class AWTPPlayerViewProgressBarViewModel: ObservableObject {
    @Published var progressValue: CGFloat = 0
    
    private let player = AWTPPlayerManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var localTime: TPPlayerTime = .zero
    
    init() {
        player.$playerTime
            .sink { newTime in
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.localTime = newTime
                    if newTime.duration != 0 {
                        self.progressValue = CGFloat(newTime.time.rounded(.up) / newTime.duration)
                        self.startTimer()
                    }
                    
                    iLog("[WC][PlayerTime] \(newTime.time.rounded(.up)) - \(newTime.duration)")
                }
            }
            .store(in: &cancellables)
        
        player.$state
            .sink { newState in
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    switch newState {
                    case .paused:
                        self.stopTimer()
                    case .stopped, .unknown, .loadingDetails:
                        self.stopTimer()
                        self.progressValue = 0
                        self.localTime = .zero
                    default:
                        return
                    }
                }
            }
            .store(in: &cancellables)
        
        player.$video
            .sink { newVideo in
                guard let _ = newVideo else { return }
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.stopTimer()
                    self.progressValue = 0
                    self.localTime = .zero
                }
            }
            .store(in: &cancellables)
    }
    
    func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {
            [weak self] _ in
            guard let self = self else { return }
            let newTime = TPPlayerTime(time: self.localTime.time + 1, duration: self.localTime.duration)
            self.localTime = newTime
            self.progressValue = newTime.duration == 0 ? 0 : CGFloat(newTime.time.rounded(.up) / newTime.duration)
            iLog("[Timer][PlayerTime] \(newTime.time.rounded(.up)) - \(newTime.duration)")
        })
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
