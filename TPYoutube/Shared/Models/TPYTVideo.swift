//
//  TPYTVideo.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation

class TPYTVideo: TPYTItemResource {
    let snippet: TPYTVideoSnippet
    let ytId: TPYTId
    let statistics: TPYTStatistics?
    
    override var id: String { ytId.videoId }
    
    override var title: String { snippet.title }
    
    override var channelTitle: String { snippet.channelTitle }
    
    override var thumbnails: TPYTVideoThumbnails { snippet.thumbnails }
    
    override var subTitle: String {
        if let viewCount = statistics?.viewCount {
            return "\(snippet.channelTitle) • \(Double(viewCount)!.formatNumber()) views • \(snippet.publishedAt.timeAgo)"
        }
        
        return "\(snippet.channelTitle) • \(snippet.publishedAt.timeAgo)"
    }
    
    override var subTitleForPlayingInfo: String {
        return snippet.channelTitle
    }
    
    override var isLiveContent: Bool {
        let superLiveContent = super.isLiveContent
        if !superLiveContent {
            return snippet.liveBroadcastContent == "live" || snippet.liveBroadcastContent == "upcoming"
        }
        
        return false
    }
    
    enum CodingKeys: CodingKey {
        case id
        case snippet
        case statistics
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.snippet = try container.decode(TPYTVideoSnippet.self, forKey: .snippet)
        self.statistics = try? container.decode(TPYTStatistics.self, forKey: .statistics)
        
        if let videoID = try? container.decode(TPYTId.self, forKey: .id) {
            self.ytId = videoID
        }
        else if let videoIdString = try? container.decode(String.self, forKey: .id) {
            self.ytId = TPYTId(videoId: videoIdString, kind: "")
        }
        else {
            throw TPYTError.decodeJsonError
        }
        
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.snippet, forKey: .snippet)
        try container.encode(self.ytId, forKey: .id)
        
        if self.statistics != nil {
            try container.encode(self.statistics!, forKey: .statistics)
        }
        
        try super.encode(to: encoder)
    }
}

class TPYTVideoSnippet: TPYTSnippet {
    let liveBroadcastContent: String
    let publishTime: Date?
    
    enum CodingKeys: CodingKey {
        case liveBroadcastContent
        case publishTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.liveBroadcastContent = (try? container.decode(String.self, forKey: .liveBroadcastContent)) ?? ""
        self.publishTime = try? container.decode(Date.self, forKey: .publishTime)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.liveBroadcastContent, forKey: .liveBroadcastContent)
        try container.encode(self.publishTime, forKey: .publishTime)
        
        try super.encode(to: encoder)
    }
}

struct TPYTId: Codable {
    let kind: String
    let videoId: String
    
    enum CodingKeys: CodingKey {
        case kind
        case videoId
    }
    
    init(videoId: String, kind: String) {
        self.videoId = videoId
        self.kind = kind
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(String.self, forKey: .kind)
        self.videoId = try container.decode(String.self, forKey: .videoId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.videoId, forKey: .videoId)
    }
}

struct TPYTStatistics: Codable {
    let viewCount: String
    let likeCount: String
    let favoriteCount: String
    let commentCount: String
    
    enum CodingKeys: CodingKey {
        case viewCount
        case likeCount
        case favoriteCount
        case commentCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.viewCount = try container.decode(String.self, forKey: .viewCount)
        self.likeCount = try container.decode(String.self, forKey: .likeCount)
        self.favoriteCount = try container.decode(String.self, forKey: .favoriteCount)
        self.commentCount = try container.decode(String.self, forKey: .commentCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.viewCount, forKey: .viewCount)
        try container.encode(self.likeCount, forKey: .likeCount)
        try container.encode(self.favoriteCount, forKey: .favoriteCount)
        try container.encode(self.commentCount, forKey: .commentCount)
    }
}
