//
//  TPYTVideoCell.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct TPYTVideoCell: View {
    @EnvironmentObject private var theme: TPTheme
    
    @State private var titleHtml: AttributedString?
    @State private var isTouchingDown = false
    @State private var currentVideoPlayed: TPYTItemResource?
    
    private let touchingAnimation: Animation = .linear(duration: 0.1)
    private var touchingDownScale: Double {
        isTouchingDown ? 0.97 : 1
    }
    
    var video: TPYTItemResource
    var onSelected: (TPYTItemResource) -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            CachedAsyncImage(url: URL(string: video.thumbnails.default.url)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .failure(_), .empty:
                    VStack {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: UIColor.systemGray5))
                default:
                    VStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: UIColor.systemGray5))
                }
            }
            .frame(width: 80 / 0.75, height: 80)
            .cornerRadius(4)

            VStack(alignment: .leading, spacing: 6) {
                if titleHtml == nil {
                    Text(video.title)
                        .appFont()
                        .lineLimit(2)
                }
                else {
                    Text(titleHtml!)
                        .appFont()
                        .lineLimit(2)
                }

                HStack {
                    if currentVideoPlayed?.id == video.id {
                        TPWaveAnimation()
                            .frame(height: 15)
                    }

                    Text(video.subTitle)
                        .appFont(13)
                        .foregroundColor(.gray)
                }
            }
        }
        .buttonStyle(.automatic)
        .scaleEffect(x: touchingDownScale, y: touchingDownScale, anchor: .center)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .onAppear {
            DispatchQueue.main.async {
                titleHtml = video.title.decodeStringToHTMLAttribute(uiFont: theme.appUIFont(.body, weight: .regular))
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) {
            viewDimensions in
            return 0
        }
        .modifier(UIButtonViewModifier(touchDownAction: {
            iLog("touchDownAction")
            withAnimation(touchingAnimation) {
                isTouchingDown = true
            }
        }, touchUpInsideAction: {
            iLog("touchUpInsideAction")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                withAnimation(touchingAnimation) {
                    isTouchingDown = false
                }
                
                onSelected(video)
            }
        }, touchCancelAction: {
            iLog("touchCancelAction")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                withAnimation(touchingAnimation) {
                    isTouchingDown = false
                }
            }
        }))
        .onReceive(TPYTPlayerManager.shared.$currentVideo) { value in
            currentVideoPlayed = value
        }
    }
}

struct TPYTVideoCell_Previews: PreviewProvider {
    static var previews: some View {
        TPYTVideoCell(video: TPYTSearchViewModel().getDumpVideos().first!, onSelected: { _ in })
            .environmentObject(TPTheme.shared)
    }
}
