//
//  TPYTSearchView.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct TPYTSearchView: View {
    @State private var searchText = ""
    @State private var isShowKeyboard = false
    
    @StateObject private var vm = TPYTSearchViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit({
                        vm.searchVideo(by: searchText)
                    })
                    .disabled(!vm.state.isDone)
                    .appFont()
            }
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 0.5)
                    .foregroundColor(Color.gray)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
            
            Spacer()
            
            List(vm.videos, id: \.id, rowContent: {
                video in
                TPYTVideoCell(video: video, onSelected: {
                    selectedVideo in
                    TPYTPlayerManager.shared.load(video: selectedVideo)
                })
                .id(video)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            })
            .listStyle(.plain)
            .opacity(vm.state.isSearching || isShowKeyboard ? 0.5 : 1)
            .overlay {
                if (isShowKeyboard) {
                    Color.white.opacity(0.01)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            hideKeyboard()
                        }
                }
                else if vm.state.isSearching {
                    ProgressView()
                        .ignoresSafeArea(.keyboard)
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .onKeyboardObserver { isShow in
            isShowKeyboard = isShow
        }
    }
}

struct TPYTSearchView_Previews: PreviewProvider {
    static var previews: some View {
        TPYTSearchView()
            .environmentObject(TPTheme.shared)
    }
}
