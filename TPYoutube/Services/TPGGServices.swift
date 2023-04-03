//
//  TPGoogleServices.swift
//  TPYoutube
//
//  Created by Thang Phung on 01/03/2023.
//

import Foundation
import Moya
import Combine
import RegexBuilder

protocol ITPGGServices {
    func getMyProfile() -> AnyPublisher<TPGGProfile, MoyaError>
    func getSuggestQueries(q: String) -> AnyPublisher<[TPSuggestion], MoyaError>
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
    
    func getSuggestQueries(q: String) -> AnyPublisher<[TPSuggestion], MoyaError> {
        return provider.requestGGPublisher(.getSuggestQueries(q: q))
            .tryMap({
                guard let text = String(data: $0.data, encoding: .ascii) else {
                    throw MoyaError.stringMapping($0)
                }
                
                let convertedString = text.mutableCopy() as? NSMutableString
                CFStringTransform(convertedString, nil, "Any-Hex/Java" as NSString, true)
                guard let convertedString = convertedString else {
                    throw MoyaError.stringMapping($0)
                }
                
                let jsonString = String(convertedString)
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!)
                if let a = json as? Array<Any>,
                    let suggests = a.first(where: { $0 is Array<String> }) as? Array<String>  {
                    return suggests.compactMap({
                        return TPSuggestion(text: $0)
                    })
                }
                
                throw MoyaError.stringMapping($0)
            })
            .mapMoyaError()
            .eraseToAnyPublisher()
    }
}
