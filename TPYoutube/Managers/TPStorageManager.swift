//
//  TPStorageManager.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation

class AppStorage {
    
}

class TPStorageManager {
    static let shared = TPStorageManager()
    static var yt: TPYTStorage { shared.yt }
    static var gg: TPGGStorage { shared.gg }
    
    private let yt = TPYTStorage()
    private let gg = TPGGStorage()
    private var historyVideos = [TPYTItemResource]()
    private var videoV1s: [String: TPYTVideoV1] = [:]
    private var videoV1Indexing: [String] = []
    private var storageQueue = DispatchQueue(label: "com.tp.yt.storage", qos: .background)
    
    func configuration() {
        storageQueue.async {
            [unowned self] in
            self.historyVideos = self.yt.getAppHistoryVideos()
            
            let (indexing, videoV1s) = self.yt.getVideosV1s()
            self.videoV1s = videoV1s
            self.videoV1Indexing = indexing
        }
    }
    
    func addVideoToHistory(video: TPYTItemResource) {
        video.setLastViewDate(date: Date.now)
        historyVideos.insert(video, at: 0)
        storageQueue.async {
            [unowned self] in
            self.yt.saveVideoToAppHistory(videos: self.historyVideos)
        }
    }
    
    func getHistoryVideos() -> [TPYTItemResource] {
        return historyVideos
    }
    
    func getVideoV1ById(videoId: String) -> TPYTVideoV1? {
        return videoV1s[videoId]
    }
    
    func saveVideoV1ById(videoId: String, videoV1: TPYTVideoV1) {
        if videoV1s[videoId] == nil {
            videoV1Indexing.append(videoId)
        }
        
        videoV1s[videoId] = videoV1
        storageQueue.async {
            [unowned self] in
            self.yt.saveVideoV1s(indexing: self.videoV1Indexing, videoV1: self.videoV1s)
        }
    }
    
    func logout() {
        yt.logout()
        gg.logout()
    }
    
    func removeTMP() {
        yt.removeTMP()
    }
}
