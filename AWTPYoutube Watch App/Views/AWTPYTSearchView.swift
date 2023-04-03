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
    @StateObject private var vm = AWTPYTSearchViewModel()
    
    var body: some View {
        ZStack {
            if case .loading = vm.state {
                ProgressView()
            }
            else {
                List(vm.videos, id: \.id) { video in
                    NavigationLink {
                        AWTPPlayerView(video: video)
                    } label: {
                        AWTPVideoCell(video: video)
                    }
                    .id(video)
                }
            }
        }
        .navigationTitle("Videos")
        .onAppear {
            vm.getSearchingVideosFromPhone()
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
