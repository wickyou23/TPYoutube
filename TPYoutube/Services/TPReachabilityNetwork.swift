//
//  TPReachabilityNetwork.swift
//  TPYoutube
//
//  Created by Thang Phung on 24/03/2023.
//

import Foundation
import Combine

class TPReachabilityNetwork {
    private(set) var tpReachabilityPublisher: AnyPublisher<Reachability.Connection, Never>?
    
    private(set) var lastConnection: Reachability.Connection = .unavailable
    private var reachabilities: [Reachability] = []
    private var hostNames: [String] = []
    
    deinit {
        reachabilities.forEach({ $0.stopNotifier() })
        for reachability in reachabilities {
            NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
        }
    }
    
    init(hostName1: String, hostName2: String? = nil, hostName3: String? = nil, hostName4: String? = nil) {
        hostNames = [hostName1]
        if let hostName2 = hostName2 {
            hostNames.append(hostName2)
        }
        
        if let hostName3 = hostName3 {
            hostNames.append(hostName3)
        }
        
        if let hostName4 = hostName4 {
            hostNames.append(hostName4)
        }
        
        reachabilities = hostNames.compactMap({ try? Reachability(hostname: $0) })
        
        var publishers: [AnyPublisher<Reachability.Connection, Never>] = []
        for item in reachabilities {
            let publisher = NotificationCenter.default.publisher(for: .reachabilityChanged, object: item)
                .compactMap { notification in
                    guard let object = notification.object as? Reachability else {
                        return Reachability.Connection.unavailable
                    }
                    
                    return object.connection
                }
                .eraseToAnyPublisher()
            
            publishers.append(publisher)
        }
        
        createCombinePublisers(publishers)
        
        if let _ = tpReachabilityPublisher {
            reachabilities.forEach({
                do {
                    try $0.startNotifier()
                } catch {
                    eLog("[Reachabilities] start with error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    private func createCombinePublisers(_ publishers: [AnyPublisher<Reachability.Connection, Never>]) {
        weak var _self = self
        func handleResponse(_ connections: [Reachability.Connection]) -> Reachability.Connection {
            var grouping = [Reachability.Connection: Int]()
            for connection in connections {
                grouping[connection] = grouping[connection] == nil ? 1 : (grouping[connection]! + 1)
            }
            
            if let a = grouping[.wifi], let b = grouping[.cellular] {
                _self?.lastConnection = a > b ? .wifi : .cellular
            }
            else if let _ = grouping[.wifi] {
                _self?.lastConnection = .wifi
            }
            else if let _ = grouping[.cellular] {
                _self?.lastConnection = .cellular
            }
            else {
                _self?.lastConnection = .unavailable
            }
            
            return _self?.lastConnection ?? .unavailable
        }
        
        if publishers.count == 1 {
            tpReachabilityPublisher = publishers[0]
                .compactMap({ c in
                    return handleResponse([c])
                })
                .eraseToAnyPublisher()
        }
        else if publishers.count == 2 {
            tpReachabilityPublisher = Publishers
                .CombineLatest(publishers[0], publishers[1])
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .compactMap({ c1, c2 in
                    return handleResponse([c1, c2])
                })
                .eraseToAnyPublisher()
        }
        else if publishers.count == 3 {
            tpReachabilityPublisher = Publishers
                .CombineLatest3(publishers[0], publishers[1], publishers[2])
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .compactMap({ c1, c2, c3 in
                    return handleResponse([c1, c2, c3])
                })
                .eraseToAnyPublisher()
        }
        else if publishers.count == 4 {
            tpReachabilityPublisher = Publishers
                .CombineLatest4(publishers[0], publishers[1], publishers[2], publishers[3])
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .compactMap({ c1, c2, c3, c4 in
                    return handleResponse([c1, c2, c3, c4])
                })
                .eraseToAnyPublisher()
        }
    }
}
