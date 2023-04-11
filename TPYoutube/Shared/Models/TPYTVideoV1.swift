//
//  TPYTPlayerDetailsV1.swift
//  TPYoutube
//
//  Created by Thang Phung on 16/03/2023.
//

import Foundation

struct TPYTVideoV1: Codable {
    var streamingData: TPYTVideoV1StreamingData
    let videoDetails: TPYTVideoV1VideoDetails
    let createdTime: Date
    
    var isExpired: Bool {
        let expiredTime = streamingData.expiresInSeconds.doubleValue ?? 0
        return Date.now.timeIntervalSince1970 >= createdTime.timeIntervalSince1970 + expiredTime
    }
    
    enum InnerResponseContextCodingKeys: CodingKey {
        case streamingData
        case videoDetails
        case createdTime
    }
    
    init(from decoder: Decoder) throws {
        let innerResponseContext = try decoder.container(keyedBy: InnerResponseContextCodingKeys.self)
        
        streamingData = try innerResponseContext.decode(TPYTVideoV1StreamingData.self, forKey: .streamingData)
        videoDetails = try innerResponseContext.decode(TPYTVideoV1VideoDetails.self, forKey: .videoDetails)
        
        if let _createdTime = try? innerResponseContext.decode(Date.self, forKey: .createdTime) {
            createdTime = _createdTime
        }
        else {
            createdTime = .now
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var innerResponseContext = encoder.container(keyedBy: InnerResponseContextCodingKeys.self)
        try innerResponseContext.encode(self.streamingData, forKey: .streamingData)
        try innerResponseContext.encode(self.videoDetails, forKey: .videoDetails)
        try innerResponseContext.encode(self.createdTime, forKey: .createdTime)
    }
    
    func getAudioURL() -> URL? {
        var streamFormat: String? = streamingData.streamingAudio234URL
        if streamFormat == nil {
            streamFormat = streamingData.streamingAudio233URL
        }
        
        if streamFormat == nil {
            streamFormat = streamingData.adaptiveFormats.first(where: { $0.itag == 140 })?.url
        }
        
        if let streamFormat = streamFormat {
            return URL(string: streamFormat)
        }
        
        return nil
    }
}

struct TPYTVideoV1StreamingData: Codable {
    let expiresInSeconds: String
    let hlsManifestUrl: String
    let aspectRatio: Double
    let serverAbrStreamingUrl: String
    let adaptiveFormats: [TPYTVideoV1AdaptiveFormats]
    var streamingAudio233URL: String?
    var streamingAudio234URL: String?
    
    var hasStreamingAudioURL: Bool {
        return streamingAudio233URL == nil || streamingAudio234URL == nil
    }
    
    enum CodingKeys: CodingKey {
        case expiresInSeconds
        case hlsManifestUrl
        case aspectRatio
        case serverAbrStreamingUrl
        case adaptiveFormats
        case streamingAudio233URL
        case streamingAudio234URL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.expiresInSeconds = try container.decode(String.self, forKey: .expiresInSeconds)
        self.hlsManifestUrl = try container.decode(String.self, forKey: .hlsManifestUrl)
        self.aspectRatio = try container.decode(Double.self, forKey: .aspectRatio)
        self.serverAbrStreamingUrl = try container.decode(String.self, forKey: .serverAbrStreamingUrl)
        self.adaptiveFormats = try container.decode([TPYTVideoV1AdaptiveFormats].self, forKey: .adaptiveFormats)
        self.streamingAudio233URL = try? container.decode(String.self, forKey: .streamingAudio233URL)
        self.streamingAudio234URL = try? container.decode(String.self, forKey: .streamingAudio234URL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.expiresInSeconds, forKey: .expiresInSeconds)
        try container.encode(self.hlsManifestUrl, forKey: .hlsManifestUrl)
        try container.encode(self.aspectRatio, forKey: .aspectRatio)
        try container.encode(self.serverAbrStreamingUrl, forKey: .serverAbrStreamingUrl)
        try container.encode(self.adaptiveFormats, forKey: .adaptiveFormats)
        
        if self.streamingAudio233URL != nil {
            try container.encode(self.streamingAudio233URL, forKey: .streamingAudio233URL)
        }
        
        if self.streamingAudio234URL != nil {
            try container.encode(self.streamingAudio234URL, forKey: .streamingAudio234URL)
        }
    }
    
    mutating func setStreamingAudioURL(audioURL: [Int: String]) {
        self.streamingAudio233URL = audioURL[233]
        self.streamingAudio234URL = audioURL[234]
    }
}

struct TPYTVideoV1AdaptiveFormats: Codable {
    let itag: Int
    let url: String
    let mimeType: String
    let bitrate: Double
    let width: Double
    let height: Double
    let lastModified: String
    let contentLength: String
    let quality: String
    let fps: Int
    let qualityLabel: String
    let projectionType: String
    let averageBitrate: Double
    let approxDurationMs: String
    
    enum CodingKeys: CodingKey {
        case itag
        case url
        case mimeType
        case bitrate
        case width
        case height
        case lastModified
        case contentLength
        case quality
        case fps
        case qualityLabel
        case projectionType
        case averageBitrate
        case approxDurationMs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.itag = try container.decode(Int.self, forKey: .itag)
        self.url = try container.decode(String.self, forKey: .url)
        self.mimeType = try container.decode(String.self, forKey: .mimeType)
        self.bitrate = try container.decode(Double.self, forKey: .bitrate)
        self.width = (try? container.decode(Double.self, forKey: .width)) ?? 0
        self.height = (try? container.decode(Double.self, forKey: .height)) ?? 0
        self.lastModified = try container.decode(String.self, forKey: .lastModified)
        self.contentLength = try container.decode(String.self, forKey: .contentLength)
        self.quality = try container.decode(String.self, forKey: .quality)
        self.fps = (try? container.decode(Int.self, forKey: .fps)) ?? 0
        self.qualityLabel = (try? container.decode(String.self, forKey: .qualityLabel)) ?? ""
        self.projectionType = try container.decode(String.self, forKey: .projectionType)
        self.averageBitrate = try container.decode(Double.self, forKey: .averageBitrate)
        self.approxDurationMs = try container.decode(String.self, forKey: .approxDurationMs)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.itag, forKey: .itag)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.mimeType, forKey: .mimeType)
        try container.encode(self.bitrate, forKey: .bitrate)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        try container.encode(self.lastModified, forKey: .lastModified)
        try container.encode(self.contentLength, forKey: .contentLength)
        try container.encode(self.quality, forKey: .quality)
        try container.encode(self.fps, forKey: .fps)
        try container.encode(self.qualityLabel, forKey: .qualityLabel)
        try container.encode(self.projectionType, forKey: .projectionType)
        try container.encode(self.averageBitrate, forKey: .averageBitrate)
        try container.encode(self.approxDurationMs, forKey: .approxDurationMs)
    }
}

struct TPYTVideoV1VideoDetails: Codable {
    let videoId: String
    let title: String
    let lengthSeconds: String
    let channelId: String
    let isOwnerViewing: Bool
    let shortDescription: String
    let viewCount: String
    let author: String
    let isLiveContent: Bool
    
    enum CodingKeys: CodingKey {
        case videoId
        case title
        case lengthSeconds
        case channelId
        case isOwnerViewing
        case shortDescription
        case viewCount
        case author
        case isLiveContent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.videoId = try container.decode(String.self, forKey: .videoId)
        self.title = try container.decode(String.self, forKey: .title)
        self.lengthSeconds = try container.decode(String.self, forKey: .lengthSeconds)
        self.channelId = try container.decode(String.self, forKey: .channelId)
        self.isOwnerViewing = try container.decode(Bool.self, forKey: .isOwnerViewing)
        self.shortDescription = try container.decode(String.self, forKey: .shortDescription)
        self.viewCount = try container.decode(String.self, forKey: .viewCount)
        self.author = try container.decode(String.self, forKey: .author)
        self.isLiveContent = try container.decode(Bool.self, forKey: .isLiveContent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.videoId, forKey: .videoId)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.lengthSeconds, forKey: .lengthSeconds)
        try container.encode(self.channelId, forKey: .channelId)
        try container.encode(self.isOwnerViewing, forKey: .isOwnerViewing)
        try container.encode(self.shortDescription, forKey: .shortDescription)
        try container.encode(self.viewCount, forKey: .viewCount)
        try container.encode(self.author, forKey: .author)
        try container.encode(self.isLiveContent, forKey: .isLiveContent)
    }
}
