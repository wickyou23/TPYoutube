//
//  TPSuggestion.swift
//  TPYoutube
//
//  Created by Thang Phung on 28/03/2023.
//

import Foundation

struct TPSuggestion: Identifiable {
    var id = UUID().uuidString
    let text: String
    let isRecent: Bool
    
    init(text: String, isRecent: Bool = false) {
        self.text = text
        self.isRecent = isRecent
    }
}
