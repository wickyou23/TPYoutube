//
//  TPVLCMetaData.swift
//  TPYoutube
//
//  Created by Thang Phung on 16/03/2023.
//

import Foundation
import MobileVLCKit
import MediaPlayer

class TPVLCMetaData {
    var video: TPYTItemResource?
    var title: String = ""
    var artworkImage: UIImage?
    var artist: String = ""
    var isAudioOnly: Bool = false
    var playbackDuration: Double = 0
    var elapsedPlaybackTime: Double = 0
    var playbackRate: Double = 0
    var position: Double = 0
    
    func updateMetadataFromMedia(video: TPYTItemResource, mediaPlayer: VLCMediaPlayer) {
        title = video.title
        artist = video.subTitleForPlayingInfo
        if let url = URL(string: video.thumbnails.high.url),
           let image = UIImage.getImageCached(from: URLRequest(url: url)) {
            artworkImage = image
        }
        
        isAudioOnly = mediaPlayer.numberOfVideoTracks == 0
        playbackDuration = Double(mediaPlayer.media!.length.intValue / 1000)
        playbackRate = Double(mediaPlayer.rate)
        if let elapsedPlaybackTime = mediaPlayer.time.value {
            self.elapsedPlaybackTime = elapsedPlaybackTime.doubleValue / 1000;
        }
        
        position = Double(mediaPlayer.position)
        populateInfoCenterFromMetadata()
        
        iLog("Video metadata updated: [playbackDuration] \(playbackDuration) - [playbackRate] \(playbackRate) - [elapsedPlaybackTime] \(self.elapsedPlaybackTime) - [position] \(mediaPlayer.position)")
    }
    
    private func populateInfoCenterFromMetadata() {
        var currentlyPlayingTrackInfo = [String: Any]()
        
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyIsLiveStream] = NSNumber(value: playbackDuration <= 0)
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyMediaType] = isAudioOnly ? NSNumber(value: MPMediaType.anyAudio.rawValue) : NSNumber(value: MPMediaType.anyVideo.rawValue)
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackProgress] = NSNumber(value: position)
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: elapsedPlaybackTime)
        currentlyPlayingTrackInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: playbackRate)
        
        currentlyPlayingTrackInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: playbackDuration)
        currentlyPlayingTrackInfo[MPMediaItemPropertyTitle] = title
        currentlyPlayingTrackInfo[MPMediaItemPropertyArtist] = artist
        
        if let artworkImage = self.artworkImage {
            currentlyPlayingTrackInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { size in
                return artworkImage
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = currentlyPlayingTrackInfo
    }
}
