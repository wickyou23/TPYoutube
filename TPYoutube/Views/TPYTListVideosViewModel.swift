//
//  TPYTListVideosViewModel.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation
import Combine

enum TPYTListVideosViewModelState {
    case getting
    case done(Error?)
    
    var isDone: Bool {
        switch self {
        case .done(_):
            return true
        default:
            return false
        }
    }
}

class TPYTListVideosViewModel: ObservableObject {
    @Published private(set) var state: TPYTListVideosViewModelState = .done(nil)
    @Published private(set) var videos: [TPYTItemResource] = []
    
    private(set) var listType: TPYTVideoType!
    private var videosSubscription: AnyCancellable?
    
    func getListVideo() {
        state = .getting
        
        videosSubscription?.cancel()
        videosSubscription = nil
        
        switch listType! {
        case .likedVideos:
            videosSubscription = TPYTAPIManager.ytService.getLikedVideos()
                .sink { completion in
                    guard case let .failure(error) = completion else { return }
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.state = .done(error)
                    }
                } receiveValue: {
                    [weak self] page in
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.videos = Array(page.items)
                        self.state = .done(nil)
                    }
                }
        case .mostPopular:
            guard let profile = TPGGAuthManager.shared.profile,
                    let regionCode = profile.locale?.region?.identifier else {
                eLog("cannot file region code of profile")
                return
            }

            videosSubscription = TPYTAPIManager.ytService.getMostPopularVideos(regionCode: regionCode)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.state = .done(error)
                    }
                } receiveValue: {
                    [weak self] page in
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.videos = Array(page.items)
                        self.state = .done(nil)
                    }
                }
        case .playListVideos(let playlist):
            videosSubscription = TPYTAPIManager.ytService.getVideosByPlaylist(playlist: playlist)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.state = .done(error)
                    }
                } receiveValue: {
                    [weak self] page in
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.videos = Array(page.items)
                        self.state = .done(nil)
                    }
                }
        case .historyVideo:
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                self.videos = Array(TPStorageManager.shared.getHistoryVideos())
                self.state = .done(nil)
            }
        }
    }
    
    func setListStype(listType: TPYTVideoType) {
        self.listType = listType
    }
}
