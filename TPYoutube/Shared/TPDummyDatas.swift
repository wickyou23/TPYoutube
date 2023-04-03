//
//  TPDumpingDatas.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation

struct TPDummyDatas {
    func getDumpVideos() -> [TPYTVideo] {
        let json = """
                    {
                      "kind": "youtube#searchListResponse",
                      "etag": "w8zSeEvBdOPTl2NRSmhot2Tuhno",
                      "nextPageToken": "CAUQAA",
                      "regionCode": "US",
                      "pageInfo": {
                        "totalResults": 1000000,
                        "resultsPerPage": 5
                      },
                      "items": [
                        {
                          "kind": "youtube#searchResult",
                          "etag": "0MM4VqvMj03p1r5WjVP3yhlo278",
                          "id": {
                            "kind": "youtube#video",
                            "videoId": "YGJyfGqNvx4"
                          },
                          "snippet": {
                            "publishedAt": "2021-04-17T04:48:29Z",
                            "channelId": "UC3kujai9joOAkHGce8H1KCw",
                            "title": "Nonstop Nhạc Khmer Remix 2021  Bong Jos Tov Khmer  Nhạc DJ Khmer",
                            "description": "Nonstop Nhạc Khmer Remix 2021 Bong Jos Tov Khmer Nhạc DJ Khmer.",
                            "thumbnails": {
                              "default": {
                                "url": "https://i.ytimg.com/vi/YGJyfGqNvx4/default.jpg",
                                "width": 120,
                                "height": 90
                              },
                              "medium": {
                                "url": "https://i.ytimg.com/vi/YGJyfGqNvx4/mqdefault.jpg",
                                "width": 320,
                                "height": 180
                              },
                              "high": {
                                "url": "https://i.ytimg.com/vi/YGJyfGqNvx4/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                              }
                            },
                            "channelTitle": "Nonstop VietMix",
                            "liveBroadcastContent": "none",
                            "publishTime": "2021-04-17T04:48:29Z"
                          }
                        },
                        {
                          "kind": "youtube#searchResult",
                          "etag": "kha2a6F-uUR9MkOLVGWD5qUewEk",
                          "id": {
                            "kind": "youtube#video",
                            "videoId": "aYugooPJKf8"
                          },
                          "snippet": {
                            "publishedAt": "2022-02-09T12:28:24Z",
                            "channelId": "UCnz6offNQYCyEMEqTRVXx3g",
                            "title": "Nonstop Nhạc Khmer Remix 2022 - SOLO AGAIN | Nhạc DJ Khmer",
                            "description": "Nonstop Nhạc Khmer Remix 2022 - SOLO AGAIN | Nhạc DJ Khmer follow me  Nhạc DJ Khmer Đăng Ký Kênh; ...",
                            "thumbnails": {
                              "default": {
                                "url": "https://i.ytimg.com/vi/aYugooPJKf8/default.jpg",
                                "width": 120,
                                "height": 90
                              },
                              "medium": {
                                "url": "https://i.ytimg.com/vi/aYugooPJKf8/mqdefault.jpg",
                                "width": 320,
                                "height": 180
                              },
                              "high": {
                                "url": "https://i.ytimg.com/vi/aYugooPJKf8/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                              }
                            },
                            "channelTitle": "Nhạc DJ Khmer",
                            "liveBroadcastContent": "none",
                            "publishTime": "2022-02-09T12:28:24Z"
                          }
                        },
                        {
                          "kind": "youtube#searchResult",
                          "etag": "wTgu5-_K2VesAAISX33tJNjatGo",
                          "id": {
                            "kind": "youtube#video",
                            "videoId": "SpRUFO_KjAA"
                          },
                          "snippet": {
                            "publishedAt": "2021-09-06T11:00:10Z",
                            "channelId": "UCnz6offNQYCyEMEqTRVXx3g",
                            "title": "Nhạc DJ Khmer 2022 - Nonstop បងចុះទៅខ្មែរ - Nhạc DJ Khmer",
                            "description": "Nhạc DJ Khmer 2021 - Nonstop បងចុះទៅខ្មែរ - Nhạc DJ Khmer Tracklist 01.Bong Jos Tov Khmer_2021_DJ MSH ft ...",
                            "thumbnails": {
                              "default": {
                                "url": "https://i.ytimg.com/vi/SpRUFO_KjAA/default.jpg",
                                "width": 120,
                                "height": 90
                              },
                              "medium": {
                                "url": "https://i.ytimg.com/vi/SpRUFO_KjAA/mqdefault.jpg",
                                "width": 320,
                                "height": 180
                              },
                              "high": {
                                "url": "https://i.ytimg.com/vi/SpRUFO_KjAA/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                              }
                            },
                            "channelTitle": "Nhạc DJ Khmer",
                            "liveBroadcastContent": "none",
                            "publishTime": "2021-09-06T11:00:10Z"
                          }
                        },
                        {
                          "kind": "youtube#searchResult",
                          "etag": "RDsEShWVboXOiBd24d6mEYr299s",
                          "id": {
                            "kind": "youtube#video",
                            "videoId": "0D9mYBJySCc"
                          },
                          "snippet": {
                            "publishedAt": "2018-02-14T02:46:19Z",
                            "channelId": "UCbw5eiTjpT34nN7h1hpNP0Q",
                            "title": "#2 New Remixes of Popular Khmer 😢 Songs ♫♬ Best Cambodia Club Party DJ Mix 2018 ♫♬ SabbyTop NonStop",
                            "description": "VinaHouse\\u200b វ៉ៃឡើ មួយម៉ោង ♫♬ New Remixes of Popular Khmer Songs ♫♬ Best Cambodia Club Party DJ Mix ...",
                            "thumbnails": {
                              "default": {
                                "url": "https://i.ytimg.com/vi/0D9mYBJySCc/default.jpg",
                                "width": 120,
                                "height": 90
                              },
                              "medium": {
                                "url": "https://i.ytimg.com/vi/0D9mYBJySCc/mqdefault.jpg",
                                "width": 320,
                                "height": 180
                              },
                              "high": {
                                "url": "https://i.ytimg.com/vi/0D9mYBJySCc/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                              }
                            },
                            "channelTitle": "SabbyTop",
                            "liveBroadcastContent": "none",
                            "publishTime": "2018-02-14T02:46:19Z"
                          }
                        },
                        {
                          "kind": "youtube#searchResult",
                          "etag": "k0B6tK26WAX8oga-cT1fH-zr15E",
                          "id": {
                            "kind": "youtube#video",
                            "videoId": "jaKN0UjexAg"
                          },
                          "snippet": {
                            "publishedAt": "2020-09-20T03:35:02Z",
                            "channelId": "UCiPaU_dl3vuDquP9RXhOMUA",
                            "title": "បទល្បីនៅ Khmer   Remix Club 2020 MLC + បទខ្លឹបថៃ    Remix New Melody Club 2020 MLC",
                            "description": "បទល្បីនៅ Khmer Remix Club 2020 MLC + បទខ្លឹបថៃ Remix New Melody Club 2020 MLC Facebook: ...",
                            "thumbnails": {
                              "default": {
                                "url": "https://i.ytimg.com/vi/jaKN0UjexAg/default.jpg",
                                "width": 120,
                                "height": 90
                              },
                              "medium": {
                                "url": "https://i.ytimg.com/vi/jaKN0UjexAg/mqdefault.jpg",
                                "width": 320,
                                "height": 180
                              },
                              "high": {
                                "url": "https://i.ytimg.com/vi/jaKN0UjexAg/hqdefault.jpg",
                                "width": 480,
                                "height": 360
                              }
                            },
                            "channelTitle": "Bảo Radley",
                            "liveBroadcastContent": "none",
                            "publishTime": "2020-09-20T03:35:02Z"
                          }
                        }
                      ]
                    }
                    """
        
        let decoder = JSONDecoder()
        var videosDump = [TPYTVideo]()
        decoder.dateDecodingStrategy = Date.getISO8601DateDecodingStrategy()
        do {
            if let jsonData = json.data(using: .utf8) {
                let page = try decoder.decode(TPYTPaging<TPYTVideo>.self, from: jsonData)
                videosDump.append(contentsOf: page.items)
            }
        }
        catch {
            eLog("Convert json error: \(error.localizedDescription)")
        }
        
        return videosDump
    }
}
