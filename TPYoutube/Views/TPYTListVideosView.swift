//
//  TPYTListVideos.swift
//  TPYoutube
//
//  Created by Thang Phung on 03/03/2023.
//

import Foundation
import SwiftUI
import Introspect

struct TPYTListVideosView: View {
    @StateObject private var vm = TPYTListVideosViewModel()
    @State private var itemSelection: TPYTItemResource?
    
    let listType: TPYTVideoType
    
    init(listType: TPYTVideoType) {
        self.listType = listType
    }
    
    var body: some View {
        VStack {
            switch vm.state {
            case .getting:
                ProgressView()
                    
            case .done(_):
                List(vm.videos, id: \.id, rowContent: {
                    video in
                    TPYTVideoCell(video: video, onSelected: { selectedVideo in
                        TPYTPlayerManager.shared.load(video: selectedVideo)
                    })
                    .tag(video)
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                })
                .listStyle(.plain)
            }
        }
        .navigationTitle(listType.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            vm.setListStype(listType: listType)
            vm.getListVideo()
        }
    }
}

struct TPYTListVideosView_Previews: PreviewProvider {
    static var previews: some View {
        TPYTListVideosView(listType: .likedVideos)
            .environmentObject(TPTheme.shared)
    }
}
