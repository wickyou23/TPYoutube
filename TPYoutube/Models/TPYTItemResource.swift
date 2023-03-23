//
//  TPYTVideo.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation

enum TPYTError: Error {
    case decodeJsonError
}

enum TPYTResourceKindType: String {
    case playlist = "playlist"
    case searchResult = "searchResult"
    case video = "video"
    case unknown
}

protocol ITPYTItemResource {
    var title: String { get }
    var subTitle: String { get }
    var thumbnails: TPYTVideoThumbnails { get }
    var channelTitle: String { get }
    var subTitleForPlayingInfo: String { get }
    var videoV1: TPYTVideoV1? { get }
    var isLiveContent: Bool { get }
}

class TPYTItemResource: ITPYTItemResource, Identifiable, Codable, Hashable {
    let kind: String
    let etag: String
    let kindType: TPYTResourceKindType
    
    private(set) var lastViewDate: Date?
    
    enum CodingKeys: CodingKey {
        case kind
        case etag
        case snippet
        case lastViewDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(String.self, forKey: .kind)
        self.etag = try container.decode(String.self, forKey: .etag)
        self.lastViewDate = try? container.decode(Date.self, forKey: .lastViewDate)
        
        let kindComponents = NSString(string: self.kind).components(separatedBy: "#")
        if kindComponents.count == 2 {
            self.kindType = TPYTResourceKindType(rawValue: kindComponents[1]) ?? .unknown
        }
        else {
            self.kindType = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.etag, forKey: .etag)
        
        if let lastViewDate = self.lastViewDate {
            try container.encode(lastViewDate, forKey: .lastViewDate)
        }
    }
    
    static func == (lhs: TPYTItemResource, rhs: TPYTItemResource) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func setLastViewDate(date: Date) {
        self.lastViewDate = date
    }
    
    var id: String { fatalError("Must Override") }
    var title: String { fatalError("Must Override") }
    var subTitle: String { fatalError("Must Override") }
    var thumbnails: TPYTVideoThumbnails {  fatalError("Must Override") }
    var channelTitle: String { fatalError("Must Override") }
    var subTitleForPlayingInfo: String { fatalError("Must Override") }
    var videoV1: TPYTVideoV1? {
        guard let _videoV1 = TPStorageManager.shared.getVideoV1ById(videoId: id) else {
            return nil
        }
        
        if _videoV1.isExpired {
            return nil
        }
        
        return _videoV1
    }
    
    var isLiveContent: Bool {
        if let videoV1 = self.videoV1 {
            return videoV1.videoDetails.isLiveContent
        }
        
        return false
    }
}

class TPYTSnippet: Codable {
    let publishedAt: Date
    let channelId: String
    let title: String
    let description: String
    let thumbnails: TPYTVideoThumbnails
    let channelTitle: String
    
    enum CodingKeys: CodingKey {
        case publishedAt
        case channelId
        case title
        case description
        case thumbnails
        case channelTitle
        case liveBroadcastContent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.publishedAt = try container.decode(Date.self, forKey: .publishedAt)
        self.channelId = try container.decode(String.self, forKey: .channelId)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.thumbnails = try container.decode(TPYTVideoThumbnails.self, forKey: .thumbnails)
        self.channelTitle = try container.decode(String.self, forKey: .channelTitle)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.publishedAt, forKey: .publishedAt)
        try container.encode(self.channelId, forKey: .channelId)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.thumbnails, forKey: .thumbnails)
        try container.encode(self.channelTitle, forKey: .channelTitle)
    }
}

struct TPYTVideoThumbnails: Codable {
    let `default`: TPYTVideoThumbnailsDetail
    let medium: TPYTVideoThumbnailsDetail
    let high: TPYTVideoThumbnailsDetail
    
    enum CodingKeys: String, CodingKey {
        case `default` = "default"
        case medium
        case high
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.default = (try? container.decode(TPYTVideoThumbnailsDetail.self, forKey: .default)) ?? .empty
        self.medium = (try? container.decode(TPYTVideoThumbnailsDetail.self, forKey: .medium)) ?? .empty
        self.high = (try? container.decode(TPYTVideoThumbnailsDetail.self, forKey: .high)) ?? .empty
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.default, forKey: .default)
        try container.encode(self.medium, forKey: .medium)
        try container.encode(self.high, forKey: .high)
    }
    
    func getRealSize(_ originSize: TPYTVideoThumbnailsDetail) -> CGSize {
        return CGSize(width: originSize.width, height: (originSize.width * medium.width) / originSize.height)
    }
}

struct TPYTVideoThumbnailsDetail: Codable {
    static let empty = TPYTVideoThumbnailsDetail(url: "", width: -1, height: -1)
    
    let url: String
    let width: Int
    let height: Int
    
    var ratio: Double {
        return Double(height / width)
    }
    
    init(url: String, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    enum CodingKeys: CodingKey {
        case url
        case width
        case height
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(String.self, forKey: .url)
        self.width = try container.decode(Int.self, forKey: .width)
        self.height = try container.decode(Int.self, forKey: .height)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
    }
}

class TPYTItemResouceContentDetails: Codable {
    required init(from decoder: Decoder) throws {
    }
    
    enum CodingKeys: CodingKey {
    }
    
    func encode(to encoder: Encoder) throws {
        _ = encoder.container(keyedBy: CodingKeys.self)
    }
}
