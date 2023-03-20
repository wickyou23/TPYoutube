//
//  TPYTAPIManager.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import Moya
import Combine
import CombineMoya

struct TPYTAPIManager {
    private static let _shared = TPYTAPIManager()
    static var ytService: ITPYTServices {
        return _shared.ytService
    }
    
    static var ggService: ITPGGServices {
        return _shared.ggService
    }
    
    private let ytService = TPYTServicesImp()
    private let ggService = TPGGServicesImp()
}

extension Publisher {
    func mapMoyaError() -> Publishers.MapError<Self, MoyaError> {
        return self.mapError({
            guard let moyaError = $0 as? MoyaError else {
                return MoyaError.underlying($0, nil)
            }
            
            return moyaError
        })
    }
}
