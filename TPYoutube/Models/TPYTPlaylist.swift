//
//  TPYTPlaylist.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation

class TPYTPlaylist: TPYTItemResource {
    let playlistId: String
    let contentDetails: TPYTPlaylistContentDetails
    let snippet: TPYTSnippet
    
    override var id: String {
        return playlistId
    }
    
    enum CodingKeys: CodingKey {
        case id
        case contentDetails
        case snippet
        case statistics
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.playlistId = try container.decode(String.self, forKey: .id)
        self.contentDetails = try container.decode(TPYTPlaylistContentDetails.self, forKey: .contentDetails)
        self.snippet = try container.decode(TPYTSnippet.self, forKey: .snippet)
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.playlistId, forKey: .id)
        try container.encode(self.contentDetails, forKey: .contentDetails)
        try container.encode(self.snippet, forKey: .snippet)
        
        try super.encode(to: encoder)
    }
}

struct TPYTPlaylistContentDetails: Codable {
    let itemCount: Int
    
    enum CodingKeys: CodingKey {
        case itemCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.itemCount = try container.decode(Int.self, forKey: .itemCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.itemCount, forKey: .itemCount)
    }
}
