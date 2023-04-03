//
//  TPYTSearchViewModel.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import Combine

enum TPYTSearchState {
    case searching, done(Error?)
    
    var isDone: Bool {
        switch self {
        case .done(_):
            return true
        default:
            return false
        }
    }
    
    var isSearching: Bool {
        switch self {
        case .searching:
            return true
        default:
            return false
        }
    }
}

enum TPYTSugesstionState {
    case searching, done(Error?)
    
    var isDone: Bool {
        switch self {
        case .done(_):
            return true
        default:
            return false
        }
    }
    
    var isSearching: Bool {
        switch self {
        case .searching:
            return true
        default:
            return false
        }
    }
}

class TPYTSearchViewModel: ObservableObject {
    @Published private(set) var suggestions: [TPSuggestion] = []
    @Published private(set) var videos: [TPYTVideo] = []
    @Published private(set) var videosDump: [TPYTVideo] = []
    
    @Published private(set) var state: TPYTSearchState = .done(nil)
    @Published private(set) var suggestionState: TPYTSugesstionState = .done(nil)
    
    private var currentPage: TPYTPaging<TPYTVideo>!
    private var videoCancellable: AnyCancellable?
    private var suggestionCancellable: AnyCancellable?
    private var searchingTimer: Timer?
    private var recentSuggestions: [TPSuggestion] = []
    private var ggSuggestions: [TPSuggestion] = []
    
    init() {
        if let cachingData = TPStorageManager.yt.getSearchingVideoPage() {
            videos.append(contentsOf: cachingData.items)
        }
        
        if let recentSuggestions = TPStorageManager.yt.getRecentSuggestions() {
            self.recentSuggestions = recentSuggestions
            suggestions = recentSuggestions
        }
    }
    
    func searchVideo(by text: String) {
        let nsText = NSString(string: text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nsText.isEmpty else {
            return
        }
        
        state = .searching
        videoCancellable?.cancel()
        videoCancellable = nil
        videoCancellable = TPYTAPIManager.ytService.searchVideos(by: text)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.state = .done(error)
                }
            } receiveValue: {
                [weak self] page in
                self?.currentPage = page
                TPStorageManager.yt.saveSearchingVideoPage(page: page)
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.videos = Array(page.items)
                    self.state = .done(nil)
                }
            }
    }
    
    func getSuggestQueries(q: String) {
        suggestionState = .searching
        searchingTimer?.invalidate()
        searchingTimer = nil
        
        let nsText = NSString(string: q).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nsText.isEmpty else {
            ggSuggestions = []
            suggestions = recentSuggestions
            suggestionState = .done(nil)
            return
        }
        
        searchingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {
            [weak self] _ in
            guard let self = self else { return }
            self.suggestionCancellable?.cancel()
            self.suggestionCancellable = nil
            self.suggestionCancellable = TPYTAPIManager.ggService.getSuggestQueries(q: nsText)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }
                    eLog(error.localizedDescription)
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.suggestionState = .done(error)
                    }
                } receiveValue: { suggestions in
                    DispatchQueue.main.async {
                        [weak self] in
                        guard let self = self else { return }
                        self.ggSuggestions = suggestions
                        self.suggestions = self.recentSuggestions + suggestions
                        self.suggestionState = .done(nil)
                    }
                }
        })
    }
    
    func saveSuggestion(suggestion: TPSuggestion) {
        DispatchQueue.global().async {
            [weak self] in
            guard let self = self else { return }
            let newSuggestion = TPSuggestion(text: suggestion.text, isRecent: true)
            if let idxExist = self.recentSuggestions.firstIndex(where: { $0.text == newSuggestion.text }) {
                self.recentSuggestions.remove(at: idxExist)
            }
            
            self.recentSuggestions.insert(newSuggestion, at: 0)
            if self.recentSuggestions.count > 10 {
                self.recentSuggestions = Array(self.recentSuggestions[0...9])
            }
            
            TPStorageManager.yt.saveRecentSuggestions(search: self.recentSuggestions)
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                self.suggestions = self.recentSuggestions + self.ggSuggestions
            }
        }
    }
}
