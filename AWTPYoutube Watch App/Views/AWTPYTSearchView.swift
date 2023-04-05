//
//  AWTPSearchView.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 30/03/2023.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct AWTPYTSearchView: View {
    @EnvironmentObject private var appVM: AWTPYoutubeAppVideModel
    @StateObject private var vm = AWTPYTSearchViewModel()

    var body: some View {
        Group {
            if appVM.wcSessionState == .activated {
                ZStack {
                    if case .loading = vm.state {
                        ProgressView()
                    }
                    else {
                        List(vm.videos, id: \.id) { video in
                            Button {
                                AWTPPlayerManager.shared.loadVideo(video: video)
                            } label: {
                                AWTPVideoCell(video: video)
                            }
                            .id(video)
                        }
                    }
                }
                .navigationTitle("Videos")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    vm.getSearchingVideosFromPhone()
                }
            }
            else {
                ProgressView()
            }
        }
    }
}

struct AWTPYTSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AWTPYTSearchView()
        }
    }
}
