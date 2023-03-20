//
//  TPYTPlaylistViewModel.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation
import Combine

enum TPYTPlaylistViewModelState {
    case getting, done(Error?)
    
    var isDone: Bool {
        switch self {
        case .done(_):
            return true
        default:
            return false
        }
    }
}

class TPYTPlaylistViewModel: ObservableObject {
    @Published private(set) var playlist: [TPYTPlaylist] = []
    @Published private(set) var state: TPYTPlaylistViewModelState = .done(nil)
    
    private var currentPage: TPYTPaging<TPYTPlaylist>!
    private var subscriptions = Set<AnyCancellable>()
    private var isGettingPlaylistForTheFirstTime = false
    
    init() {
        if let cachingData = TPStorageManager.yt.getPlaylistPage() {
            playlist = Array(cachingData.items)
        }
    }
    
    func getPlaylistForFirstTimeAppear() {
        if isGettingPlaylistForTheFirstTime {
           return
        }
        
        getPlaylist()
        isGettingPlaylistForTheFirstTime = true
    }
    
    func getPlaylist() {
        if playlist.isEmpty {
            state = .getting
        }
        
        TPYTAPIManager.ytService.getPlaylist()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.state = .done(error)
                }
            } receiveValue: {
                [weak self] page in
                self?.currentPage = page
                TPStorageManager.yt.savePlaylistPage(page: page)
                DispatchQueue.main.async {
                    [weak self] in
                    guard let self = self else { return }
                    self.playlist = Array(page.items)
                    self.state = .done(nil)
                }
            }
            .store(in: &subscriptions)
    }
    
    
    func getDumpPlaylist() -> [TPYTPlaylist] {
        let json = """
                    {
                        "kind": "youtube#playlistListResponse",
                        "etag": "y-3Y7TT-KJvuU6h8HXrMs5ZDJvg",
                        "pageInfo": {
                            "totalResults": 8,
                            "resultsPerPage": 50
                        },
                        "items": [
                            {
                                "kind": "youtube#playlist",
                                "etag": "6Rs_NFQm8QFf3XM9jrKv_cOjSRY",
                                "id": "PL7TLiL-8tJkfKJ-H2280lZYrOJopaNbp3",
                                "snippet": {
                                    "publishedAt": "2015-03-12T18:07:28Z",
                                    "channelId": "UC2219AsQxCFKrJiL90hJxiA",
                                    "title": "Y Phương",
                                    "description": "",
                                    "thumbnails": {
                                        "default": {
                                            "url": "https://i.ytimg.com/vi/oZ_pOkjCCpk/default.jpg",
                                            "width": 120,
                                            "height": 90
                                        },
                                        "medium": {
                                            "url": "https://i.ytimg.com/vi/oZ_pOkjCCpk/mqdefault.jpg",
                                            "width": 320,
                                            "height": 180
                                        },
                                        "high": {
                                            "url": "https://i.ytimg.com/vi/oZ_pOkjCCpk/hqdefault.jpg",
                                            "width": 480,
                                            "height": 360
                                        },
                                        "standard": {
                                            "url": "https://i.ytimg.com/vi/oZ_pOkjCCpk/sddefault.jpg",
                                            "width": 640,
                                            "height": 480
                                        },
                                        "maxres": {
                                            "url": "https://i.ytimg.com/vi/oZ_pOkjCCpk/maxresdefault.jpg",
                                            "width": 1280,
                                            "height": 720
                                        }
                                    },
                                    "channelTitle": "Thang Phung",
                                    "localized": {
                                        "title": "Y Phương",
                                        "description": ""
                                    }
                                },
                                "status": {
                                    "privacyStatus": "public"
                                },
                                "contentDetails": {
                                    "itemCount": 5
                                }
                            },
                            {
                                "kind": "youtube#playlist",
                                "etag": "GtMG8crKpfAJIw71vdfo2WIgW84",
                                "id": "PL7TLiL-8tJkfRi9F6akS-PHd0r2djhaEB",
                                "snippet": {
                                    "publishedAt": "2013-11-05T16:24:28Z",
                                    "channelId": "UC2219AsQxCFKrJiL90hJxiA",
                                    "title": "BaiGiang",
                                    "description": "",
                                    "thumbnails": {
                                        "default": {
                                            "url": "https://i.ytimg.com/vi/NKRPQ2NPTwQ/default.jpg",
                                            "width": 120,
                                            "height": 90
                                        },
                                        "medium": {
                                            "url": "https://i.ytimg.com/vi/NKRPQ2NPTwQ/mqdefault.jpg",
                                            "width": 320,
                                            "height": 180
                                        },
                                        "high": {
                                            "url": "https://i.ytimg.com/vi/NKRPQ2NPTwQ/hqdefault.jpg",
                                            "width": 480,
                                            "height": 360
                                        },
                                        "standard": {
                                            "url": "https://i.ytimg.com/vi/NKRPQ2NPTwQ/sddefault.jpg",
                                            "width": 640,
                                            "height": 480
                                        },
                                        "maxres": {
                                            "url": "https://i.ytimg.com/vi/NKRPQ2NPTwQ/maxresdefault.jpg",
                                            "width": 1280,
                                            "height": 720
                                        }
                                    },
                                    "channelTitle": "Thang Phung",
                                    "localized": {
                                        "title": "BaiGiang",
                                        "description": ""
                                    }
                                },
                                "status": {
                                    "privacyStatus": "public"
                                },
                                "contentDetails": {
                                    "itemCount": 2
                                }
                            },
                            {
                                "kind": "youtube#playlist",
                                "etag": "kDQxQvENFYJQgckv1zzTJHVGL-M",
                                "id": "PL7TLiL-8tJkdQvTNo5RYqOCa4NP8sI5M_",
                                "snippet": {
                                    "publishedAt": "2013-05-17T06:35:55Z",
                                    "channelId": "UC2219AsQxCFKrJiL90hJxiA",
                                    "title": "Nhạc Vàng",
                                    "description": "",
                                    "thumbnails": {
                                        "default": {
                                            "url": "https://i.ytimg.com/vi/i9TDuj_rgyE/default.jpg",
                                            "width": 120,
                                            "height": 90
                                        },
                                        "medium": {
                                            "url": "https://i.ytimg.com/vi/i9TDuj_rgyE/mqdefault.jpg",
                                            "width": 320,
                                            "height": 180
                                        },
                                        "high": {
                                            "url": "https://i.ytimg.com/vi/i9TDuj_rgyE/hqdefault.jpg",
                                            "width": 480,
                                            "height": 360
                                        },
                                        "standard": {
                                            "url": "https://i.ytimg.com/vi/i9TDuj_rgyE/sddefault.jpg",
                                            "width": 640,
                                            "height": 480
                                        },
                                        "maxres": {
                                            "url": "https://i.ytimg.com/vi/i9TDuj_rgyE/maxresdefault.jpg",
                                            "width": 1280,
                                            "height": 720
                                        }
                                    },
                                    "channelTitle": "Thang Phung",
                                    "localized": {
                                        "title": "Nhạc Vàng",
                                        "description": ""
                                    }
                                },
                                "status": {
                                    "privacyStatus": "public"
                                },
                                "contentDetails": {
                                    "itemCount": 29
                                }
                            },
                            {
                                "kind": "youtube#playlist",
                                "etag": "rjx4YBLUX5UI6a6eUxAr0Dw6Phg",
                                "id": "FL2219AsQxCFKrJiL90hJxiA",
                                "snippet": {
                                    "publishedAt": "2012-08-21T03:20:01Z",
                                    "channelId": "UC2219AsQxCFKrJiL90hJxiA",
                                    "title": "Favorites",
                                    "description": "",
                                    "thumbnails": {
                                        "default": {
                                            "url": "https://i.ytimg.com/img/no_thumbnail.jpg",
                                            "width": 120,
                                            "height": 90
                                        },
                                        "medium": {
                                            "url": "https://i.ytimg.com/img/no_thumbnail.jpg",
                                            "width": 320,
                                            "height": 180
                                        },
                                        "high": {
                                            "url": "https://i.ytimg.com/img/no_thumbnail.jpg",
                                            "width": 480,
                                            "height": 360
                                        }
                                    },
                                    "channelTitle": "Thang Phung",
                                    "defaultLanguage": "en",
                                    "localized": {
                                        "title": "Favorites",
                                        "description": ""
                                    }
                                },
                                "status": {
                                    "privacyStatus": "public"
                                },
                                "contentDetails": {
                                    "itemCount": 0
                                }
                            }
                        ]
                    }
                    """
        
        let decoder = JSONDecoder()
        var playlistDump = [TPYTPlaylist]()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            if let jsonData = json.data(using: .utf8) {
                let page = try decoder.decode(TPYTPaging<TPYTPlaylist>.self, from: jsonData)
                playlistDump.append(contentsOf: page.items)
            }
        }
        catch {
            eLog("Convert json error: \(error.localizedDescription)")
        }
        
        return playlistDump
    }
}
