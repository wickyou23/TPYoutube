//
//  TPYTVideoPaing.swift
//  TPYoutube
//
//  Created by Thang Phung on 23/02/2023.
//

import Foundation

enum TPYTPagingKindType: String {
    case playlistListResponse, searchListResponse, videoListResponse, unknown
}

class TPYTPaging<T: TPYTItemResource>: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: TPYTPage
    let items: [T]
    let kindType: TPYTPagingKindType
    
    enum CodingKeys: CodingKey {
        case kind
        case etag
        case nextPageToken
        case regionCode
        case pageInfo
        case items
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.kind = try container.decode(String.self, forKey: .kind)
        self.etag = try container.decode(String.self, forKey: .etag)
        self.pageInfo = try container.decode(TPYTPage.self, forKey: .pageInfo)
        self.items = try container.decode([T].self, forKey: .items)
        
        if container.contains(.nextPageToken) {
            self.nextPageToken = try container.decode(String.self, forKey: .nextPageToken)
        }
        else {
            self.nextPageToken = nil
        }
        
        if container.contains(.regionCode) {
            self.regionCode = try container.decode(String.self, forKey: .regionCode)
        }
        else {
            self.regionCode = nil
        }
        
        let kindComponents = NSString(string: self.kind).components(separatedBy: "#")
        if kindComponents.count == 2 {
            self.kindType = TPYTPagingKindType(rawValue: kindComponents[1]) ?? .unknown
        }
        else {
            self.kindType = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.kind, forKey: .kind)
        try container.encode(self.etag, forKey: .etag)
        try container.encode(self.pageInfo, forKey: .pageInfo)
        try container.encode(self.items, forKey: .items)
        
        if nextPageToken != nil {
            try container.encode(self.nextPageToken, forKey: .nextPageToken)
        }
        
        if regionCode != nil {
            try container.encode(self.regionCode, forKey: .regionCode)
        }
    }
}

struct TPYTPage: Codable {
    let totalResults: Int
    let resultsPerPage: Int
    
    enum CodingKeys: CodingKey {
        case totalResults
        case resultsPerPage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalResults = try container.decode(Int.self, forKey: .totalResults)
        self.resultsPerPage = try container.decode(Int.self, forKey: .resultsPerPage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.totalResults, forKey: .totalResults)
        try container.encode(self.resultsPerPage, forKey: .resultsPerPage)
    }
}
