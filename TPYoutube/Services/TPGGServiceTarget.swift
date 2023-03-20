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
}

extension TPGGServiceTarget: ITPGGServiceTargetType {
    var baseURL: URL {
        URL(string: "https://www.googleapis.com/oauth2/v3")!
    }
    
    var path: String {
        switch self {
        case .getMyProfile:
            return "/userinfo"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getMyProfile:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getMyProfile:
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        var customHeader = ["Accept": "application/json"]
        if let ytAuth = TPGGAuthManager.shared.authorization,
           let accessToken = ytAuth.authState.lastTokenResponse?.accessToken {
            customHeader["Authorization"] = "Bearer \(accessToken)"
        }
        
        return customHeader
    }
}
