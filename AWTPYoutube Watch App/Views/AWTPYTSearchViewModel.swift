//
//  AWTPSearchViewModel.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import Foundation

enum AWTPYTSearchViewModelState {
    case loading
    case done(Error?)
}

class AWTPYTSearchViewModel: ObservableObject {
    @Published var videos: [TPYTItemResource] = []
    @Published var state: AWTPYTSearchViewModelState = .done(nil)
    
    private let wcCommand = AWTPWCSessionCommands()
    
    func getSearchingVideosFromPhone() {
//        videos = TPDummyDatas().getDumpVideos()
        
        state = .loading
        wcCommand.getSearchingVideos {
            [weak self] paging, error in
            guard let self = self else { return }
            if let error = error {
                eLog("\(error.localizedDescription)")
                self.state = .done(error)
                return
            }

            self.videos = paging?.items ?? []
            self.state = .done(nil)
        }
    }
}
