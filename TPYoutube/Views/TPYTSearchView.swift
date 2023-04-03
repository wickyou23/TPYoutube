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
            HStack(spacing: 4) {
                if isShowKeyboard {
                    Button {
                        hideKeyboard()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 10)
                            .foregroundColor(.gray)
                    }
                    .padding(EdgeInsets(top: 26, leading: 16, bottom: 10, trailing: 16))
                }
                
                HStack {
                    TextField("Search videos", text: $searchText)
                        .appFont()
                        .submitLabel(.search)
                        .onSubmit({
                            vm.searchVideo(by: searchText)
                        })
                        .onChange(of: searchText, perform: {
                            newValue in
                            guard isShowKeyboard || searchText.isEmpty else { return }
                            vm.getSuggestQueries(q: newValue)
                        })
                        .onAppear {
                            UITextField.appearance().clearButtonMode = .whileEditing
                        }
                        .disabled(!vm.state.isDone)
                    
                    if case .searching = vm.suggestionState {
                        ProgressView()
                    }
                }
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 0.5)
                        .foregroundColor(Color.gray)
                }
                .padding(EdgeInsets(top: 16, leading: isShowKeyboard ? 0 : 16, bottom: 0, trailing: 16))
            }
            .frame(alignment: .center)
            
            Spacer()
            
            if !isShowKeyboard {
                List(vm.videos, id: \.id, rowContent: {
                    video in
                    TPYTVideoCell(video: video, onSelected: {
                        selectedVideo in
                        TPYTPlayerManager.shared.load(video: selectedVideo, playlist: vm.videos)
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
            else {
                List(vm.suggestions) {
                    item in
                    HStack(spacing: 12) {
                        if item.isRecent {
                            Image(systemName: "clock")
                        }
                        else {
                            Image(systemName: "magnifyingglass")
                        }
                        
                        Text(item.text)
                            .appFont()
                    }
                    .onTapGesture {
                        searchText = item.text
                        vm.searchVideo(by: searchText)
                        vm.saveSuggestion(suggestion: item)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.1))
                }
                .listStyle(.plain)
                .padding(.zero)
            }
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
