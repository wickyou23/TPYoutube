//
//  TPGGProfile.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation

struct TPGGProfile: Codable {
    let sub: String
    let name: String
    let givenName: String
    let familyName: String
    let picture: String
    let localeString: String
    
    var fullName: String {
        return givenName + " " + familyName
    }
    
    var locale: Locale? {
        return Locale(identifier: localeString)
    }
    
    enum CodingKeys: String, CodingKey {
        case sub
        case name
        case givenName = "given_name"
        case familyName = "family_name"
        case picture
        case locale
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sub = try container.decode(String.self, forKey: .sub)
        self.name = try container.decode(String.self, forKey: .name)
        self.givenName = try container.decode(String.self, forKey: .givenName)
        self.familyName = try container.decode(String.self, forKey: .familyName)
        self.picture = try container.decode(String.self, forKey: .picture)
        self.localeString = try container.decode(String.self, forKey: .locale)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.sub, forKey: .sub)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.givenName, forKey: .givenName)
        try container.encode(self.familyName, forKey: .familyName)
        try container.encode(self.picture, forKey: .picture)
        try container.encode(self.localeString, forKey: .locale)
    }
}
