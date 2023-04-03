//
//  TPYTStorageManager.swift
//  TPYoutube
//
//  Created by Thang Phung on 24/02/2023.
//

import Foundation

private struct TPYTStorageKey {
    static let youtubeVideoPageKey = "youtubeVideoPageKey"
    static let youtubePlaylistPageKey = "youtubePlaylistPageKey"
    static let appHistoryVideos = "appHistoryVideos#video"
    static let appHistoryPlaylistVideos = "appHistoryVideos#playlist"
    static let youtubeVideoV1Key = "youtubeVideoV1Key"
    static let recentSuggestionKey = "recentSuggestionKey"
    
    fileprivate static let youtubeVideoV1IndexingKey = "youtubeVideoV1Key#indexing"
}

struct TPYTStorage {
    private let ud = UserDefaults.standard
    
    func saveSearchingVideoPage(page: TPYTPaging<TPYTVideo>) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        do {
            let datas = try encoder.encode(page)
            ud.set(datas, forKey: TPYTStorageKey.youtubeVideoPageKey)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
//    func getSearchingVideoPage() -> TPYTPaging<TPYTVideo>? {
//        guard let data = ud.data(forKey: TPYTStorageKey.youtubeVideoPageKey) else {
//            iLog("Caching Data not found")
//            return nil
//        }
//        
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
//        do {
//            return try decoder.decode(TPYTPaging<TPYTVideo>.self, from: data)
//        } catch {
//            eLog("[JSONDecoder]: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
    func getSearchingVideoPage<T: Decodable>(type: T.Type = TPYTPaging<TPYTVideo>.self) -> T? {
        guard let data = ud.data(forKey: TPYTStorageKey.youtubeVideoPageKey) else {
            iLog("Caching Data not found")
            return nil
        }
        
        if T.self == Data.self {
            return data as? T
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            eLog("[JSONDecoder]: \(error.localizedDescription)")
            return nil
        }
    }
    
    func savePlaylistPage(page: TPYTPaging<TPYTPlaylist>) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        do {
            let datas = try encoder.encode(page)
            ud.set(datas, forKey: TPYTStorageKey.youtubePlaylistPageKey)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
    func getPlaylistPage() -> TPYTPaging<TPYTPlaylist>? {
        guard let data = ud.data(forKey: TPYTStorageKey.youtubePlaylistPageKey) else {
            iLog("Caching Data not found")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            return try decoder.decode(TPYTPaging<TPYTPlaylist>.self, from: data)
        } catch {
            eLog("[JSONDecoder] \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveVideoToAppHistory(videos: [TPYTItemResource]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        
        var mVideos = [TPYTItemResource]()
        if videos.count > 100 {
            mVideos = Array(videos[0...99])
        }
        else {
            mVideos = videos
        }
        
        var videoItems = [TPYTVideo]()
        var playlistItems = [TPYTPlaylist]()
        for item in mVideos {
            if let videoItem = item as? TPYTVideo {
                videoItems.append(videoItem)
            }
            else if let playlistItem = item as? TPYTPlaylist {
                playlistItems.append(playlistItem)
            }
        }
        
        do {
            let videoDatas = try encoder.encode(videoItems)
            let playlistDatas = try encoder.encode(playlistItems)
            
            ud.set(videoDatas, forKey: TPYTStorageKey.appHistoryVideos)
            ud.set(playlistDatas, forKey: TPYTStorageKey.appHistoryPlaylistVideos)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
    func getAppHistoryVideos() -> [TPYTItemResource] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        
        var videoItems = [TPYTVideo]()
        var playlistItems = [TPYTPlaylist]()
        if let videoDatas = ud.data(forKey: TPYTStorageKey.appHistoryVideos),
           let videos = try? decoder.decode([TPYTVideo].self, from: videoDatas) {
            videoItems.append(contentsOf: videos)
        }
        
        if let playlistItemDatas = ud.data(forKey: TPYTStorageKey.appHistoryPlaylistVideos),
           let videos = try? decoder.decode([TPYTPlaylist].self, from: playlistItemDatas) {
            playlistItems.append(contentsOf: videos)
        }
        
        let combineVides: [TPYTItemResource] = videoItems + playlistItems
        return combineVides.sorted { a, b in
            a.lastViewDate! > b.lastViewDate!
        }
    }
    
    func saveVideoV1s(indexing: [String], videoV1: [String: TPYTVideoV1]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        
        var tmpVideoV1 = videoV1
        var tmpIndexing = indexing
        while tmpIndexing.count > 100 {
            let first = tmpIndexing.removeFirst()
            tmpVideoV1.removeValue(forKey: first)
        }
        
        do {
            let indexing = try encoder.encode(tmpIndexing)
            let datas = try encoder.encode(tmpVideoV1)
            ud.set(datas, forKey: TPYTStorageKey.youtubeVideoV1Key)
            ud.set(indexing, forKey: TPYTStorageKey.youtubeVideoV1IndexingKey)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
    func getVideosV1s() -> (indexing: [String], datas: [String: TPYTVideoV1]) {
        guard let data = ud.data(forKey: TPYTStorageKey.youtubeVideoV1Key),
              let indexingData = ud.data(forKey: TPYTStorageKey.youtubeVideoV1IndexingKey) else {
            iLog("Caching Data not found")
            return ([], [:])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            let videosV1 = try decoder.decode([String: TPYTVideoV1].self, from: data)
            let indexing = try decoder.decode([String].self, from: indexingData)
            return (indexing, videosV1)
        } catch {
            eLog("[JSONDecoder] \(error.localizedDescription)")
            return ([], [:])
        }
    }
    
    func saveRecentSuggestions(search: [TPSuggestion]) {
        let encoder = JSONEncoder()
        do {
            let datas = try encoder.encode(search.compactMap({ $0.text }))
            ud.set(datas, forKey: TPYTStorageKey.recentSuggestionKey)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
    func getRecentSuggestions() -> [TPSuggestion]? {
        guard let data = ud.data(forKey: TPYTStorageKey.recentSuggestionKey) else {
            iLog("Caching Data not found")
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let texts = try decoder.decode([String].self, from: data)
            return texts.compactMap({ TPSuggestion(text: $0, isRecent: true) })
        } catch {
            eLog("[JSONDecoder]: \(error.localizedDescription)")
            return nil
        }
    }
    
    func logout() {
        ud.removeObject(forKey: TPYTStorageKey.youtubePlaylistPageKey)
    }
    
    func removeTMP() {
        ud.removeObject(forKey: TPYTStorageKey.appHistoryVideos)
    }
}
