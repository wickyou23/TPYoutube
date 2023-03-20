//
//  TPYTYoutubeMoyaProvider.swift
//  TPYoutube
//
//  Created by Thang Phung on 27/02/2023.
//

import Foundation
import Combine
import CombineMoya
import Moya

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class TPGGMoyaPublisher<Output>: Publisher {

    typealias Failure = MoyaError

    private class Subscription: Combine.Subscription {
        private let performCall: () -> Moya.Cancellable?
        private var cancellable: Moya.Cancellable?

        init(subscriber: AnySubscriber<Output, MoyaError>, callback: @escaping (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?) {
            performCall = {
                callback(subscriber)
            }
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > .none else { return }

            cancellable = performCall()
        }

        func cancel() {
            cancellable?.cancel()
        }
    }

    private let callback: (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?

    init(callback: @escaping (AnySubscriber<Output, MoyaError>) -> Moya.Cancellable?) {
        self.callback = callback
    }

    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(subscriber: AnySubscriber(subscriber), callback: callback)
        subscriber.receive(subscription: subscription)
    }
}

class TPGGMoyaProvider<TargetType: ITPGGServiceTargetType>: MoyaProvider<TargetType> {
    private typealias PendingRequestType = (Target, AnySubscriber<Response, MoyaError>, Response)
    
    private var pendingRequest: [PendingRequestType] = []
    private var isRefreshingToken = false
    private let youtubeAPIQueue = DispatchQueue(label: "com.tp.youtubeAPI", qos: .default)
    
    func requestGGPublisher(_ target: Target) -> AnyPublisher<Response, MoyaError> {
        return TPGGMoyaPublisher { [weak self] subscriber in
            return self?.request(target, callbackQueue: self?.youtubeAPIQueue, progress: nil) {
                    [weak self] result in
                    switch result {
                    case let .success(response):
                        if response.statusCode == 401 {
                            self?.pendingRequest.append((target, subscriber, response))
                            if self?.isRefreshingToken == false {
                                self?.doRefreshYoutubeToken()
                            }
                            
                            return
                        }
                        
                        _ = subscriber.receive(response)
                        subscriber.receive(completion: .finished)
                    case let .failure(error):
                        subscriber.receive(completion: .failure(error))
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    fileprivate func doRefreshYoutubeToken() {
        isRefreshingToken = true
        TPGGAuthManager.shared.refreshYoutubeToken {
            [weak self] isSuccess in
            guard let self = self else { return }
            for (target, subscriber, originResponse) in self.pendingRequest {
                if !isSuccess {
                    _ = subscriber.receive(originResponse)
                    subscriber.receive(completion: .finished)
                }
                else {
                    self.request(target, callbackQueue: self.youtubeAPIQueue, progress: nil) { result in
                        switch result {
                        case let .success(response):
                            if response.statusCode == 401,
                                TPGGAuthManager.shared.state == .authorized {
                                TPGGAuthManager.shared.logout()
                                return
                            }
                            
                            _ = subscriber.receive(response)
                            subscriber.receive(completion: .finished)
                        case let .failure(error):
                            subscriber.receive(completion: .failure(error))
                        }
                    }
                }
            }
            
            self.pendingRequest.removeAll()
            self.isRefreshingToken = false
        }
    }
}
