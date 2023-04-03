//
//  TPGGServicesTarget.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation
import Moya

enum TPGGServiceTarget {
    case getMyProfile
    case getSuggestQueries(q: String)
}

extension TPGGServiceTarget: ITPGGServiceTargetType {
    var baseURL: URL {
        switch self {
        case .getMyProfile:
            return URL(string: "https://www.googleapis.com")!
        case .getSuggestQueries:
            return URL(string: "https://suggestqueries.google.com")!
        }
    }
    
    var path: String {
        switch self {
        case .getMyProfile:
            return "/oauth2/v3/userinfo"
        case .getSuggestQueries:
            return "/complete/search"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getMyProfile, .getSuggestQueries:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getMyProfile:
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case .getSuggestQueries(let q):
            let params = [
                "client": "firefox",
                "q": q
            ]
            
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .getMyProfile:
            var customHeader = ["Accept": "application/json"]
            if let ytAuth = TPGGAuthManager.shared.authorization,
               let accessToken = ytAuth.authState.lastTokenResponse?.accessToken {
                customHeader["Authorization"] = "Bearer \(accessToken)"
            }
            
            return customHeader
        case .getSuggestQueries(_):
            return nil
        }
    }
}
