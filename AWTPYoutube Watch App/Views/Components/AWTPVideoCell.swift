//
//  AWTPVideoCell.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 03/04/2023.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct AWTPVideoCell: View {
    @State private var cachedThumbnailImg: Image?
    
    let video: TPYTItemResource
    
    @ViewBuilder
    var thumbnailImageView: some View {
        if let thumbnailImage = self.cachedThumbnailImg {
            thumbnailImage.resizable()
        }
        else {
            CachedAsyncImage(url: URL(string: video.thumbnails.default.url)) { phase in
                switch phase {
                case .success(let image):
                    Color.clear
                        .onAppear {
                            cachedThumbnailImg = image
                        }
                case .failure(_):
                    VStack {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    VStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            thumbnailImageView
                .frame(width: 35 / 0.75, height: 35)
            
            VStack(alignment: .leading) {
                Text(video.title)
                    .lineLimit(1)
                    .appFont(12)
                Text(video.channelTitle)
                    .lineLimit(1)
                    .foregroundColor(.gray)
                    .appFont(10)
            }
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
    }
}

struct AWTPVideoCell_Previews: PreviewProvider {
    static var previews: some View {
        AWTPVideoCell(video: TPDummyDatas().getDumpVideos().first!)
    }
}
