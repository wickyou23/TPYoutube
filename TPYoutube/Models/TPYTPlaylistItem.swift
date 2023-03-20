//
//  TPYTPlaylistItem.swift
//  TPYoutube
//
//  Created by Thang Phung on 06/03/2023.
//

import Foundation

class TPYTPlaylistItem: TPYTItemResource {
    let snippet: TPYTPlaylistItemSnippet
    let contentDetails: TPYTPlaylistItemContentDetails
    
    override var id: String { snippet.resourceId.videoId }
    
    override var title: String { snippet.title }
    
    override var channelTitle: String { snippet.channelTitle }
    
    override var thumbnails: TPYTVideoThumbnails { snippet.thumbnails }
    
    override var subTitle: String {
        return "\(snippet.channelTitle) • \(snippet.publishedAt.timeAgo)"
    }
    
    enum CodingKeys: CodingKey {
        case snippet
        case contentDetails
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.snippet = try container.decode(TPYTPlaylistItemSnippet.self, forKey: .snippet)
        self.contentDetails = try container.decode(TPYTPlaylistItemContentDetails.self, forKey: .contentDetails)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.snippet, forKey: .snippet)
        try container.encode(self.contentDetails, forKey: .contentDetails)
        
        try super.encode(to: encoder)
    }
}

class TPYTPlaylistItemSnippet: TPYTSnippet {
    let resourceId: TPYTId
    
    enum CodingKeys: CodingKey {
        case resourceId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.resourceId = try container.decode(TPYTId.self, forKey: .resourceId)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.resourceId, forKey: .resourceId)
        
        try super.encode(to: encoder)
    }
}

class TPYTPlaylistItemContentDetails: TPYTItemResouceContentDetails {
    let videoId: String
    let videoPublishedAt: Date?
    
    enum CodingKeys: CodingKey {
        case videoId
        case videoPublishedAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.videoId = try container.decode(String.self, forKey: .videoId)
        self.videoPublishedAt = try? container.decode(Date.self, forKey: .videoPublishedAt)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.videoId, forKey: .videoId)
        
        if self.videoPublishedAt != nil {
            try container.encode(self.videoPublishedAt!, forKey: .videoPublishedAt)
        }
        
        try super.encode(to: encoder)
    }
}
