//
//  TPGoogleServices.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation
import Moya
import Combine

protocol ITPGGServices {
    func getMyProfile() -> AnyPublisher<TPGGProfile, MoyaError>
}

struct TPGGServicesImp: ITPGGServices {
    let provider: TPGGMoyaProvider<TPGGServiceTarget>!
    var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        return decoder
    }
    
    init() {
        provider = .init(plugins: [NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(logOptions: NetworkLoggerPlugin.Configuration.LogOptions.verbose))])
    }
    
    func getMyProfile() -> AnyPublisher<TPGGProfile, MoyaError> {
        return provider.requestGGPublisher(.getMyProfile)
            .tryMap({ $0.data })
            .decode(type: TPGGProfile.self, decoder: jsonDecoder)
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
}
