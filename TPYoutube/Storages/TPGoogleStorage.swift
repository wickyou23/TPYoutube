//
//  TPGoogleStorage.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation

private struct TPGGStorageKey {
    static let ggProfileKey = "ggProfileKey"
}

struct TPGGStorage {
    private let ud = UserDefaults.standard
    
    func saveProfile(profile: TPGGProfile) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = Date.getISO8601DateEncodingStrategy()
        do {
            let datas = try encoder.encode(profile)
            ud.set(datas, forKey: TPGGStorageKey.ggProfileKey)
        } catch {
            eLog("[JSONEncoder] \(error.localizedDescription)")
        }
    }
    
    func getProfile() -> TPGGProfile? {
        guard let data = ud.data(forKey: TPGGStorageKey.ggProfileKey) else {
            iLog("Caching Data not found")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            return try decoder.decode(TPGGProfile.self, from: data)
        } catch {
            eLog("[JSONDecoder] \(error.localizedDescription)")
            return nil
        }
    }
    
    func logout() {
        ud.removeObject(forKey: TPGGStorageKey.ggProfileKey)
    }
}
