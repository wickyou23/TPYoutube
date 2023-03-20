//
//  TPYTPlaylistView.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import SwiftUI
import CachedAsyncImage

struct TPYTPlaylistView: View {
    @EnvironmentObject private var authManager: TPGGAuthManager
    
    var body: some View {
//        AuthView()
        
        VStack {
            switch authManager.state {
            case .processing:
                ProgressView()
            case .unAuthorized:
                Button {
                    authManager.loginWithYoutubeAccount()
                } label: {
                    HStack {
                        Image("ic_youtube")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Login with Youtube Account")
                            .foregroundColor(.black)
                            .appFont()
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                .shadow(color: Color(UIColor.systemGray4), radius: 3, x: 3, y: 3)
            case .authorized:
                AuthView()
            }
        }
    }
}

private struct AuthView: View {
    @EnvironmentObject private var authManager: TPGGAuthManager
    @EnvironmentObject private var appVM: AppViewModel
    
    @StateObject private var vm = TPYTPlaylistViewModel()
    
    var body: some View {
        List {
            HStack(spacing: 16) {
                CachedAsyncImage(url: URL(string: authManager.profile?.picture ?? "")) { image in
                    image
                        .resizable()
                        .frame(width: 60, height: 60)
                        .cornerRadius(30)
                        .overlay {
                            Circle()
                                .strokeBorder(.red, lineWidth: 2)
                        }
                    
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color(uiColor: .darkGray))
                }
                
                Text(authManager.profile?.fullName ?? "No name")
                    .appFont(20, weight: .medium)
                
                Spacer()
                
                Button {
                    appVM.showPopupLogout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderless)
                .offset(x: 16)
            }
            .id("Profile_Row")
            .listRowSeparator(.automatic, edges: .bottom)
            .listRowSeparator(.hidden, edges: .top)
            .alignmentGuide(.listRowSeparatorLeading) {
                viewDimensions in
                return 0
            }
            
            NavigationLink {
                TPYTListVideosView(listType: .likedVideos)
            } label: {
                HStack(spacing: 20) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.gray)
                    
                    Text("Liked videos")
                        .appFont()
                }
                .frame(height: 40)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            }
            .id("hand.thumbsup.fill")
            
            NavigationLink {
                TPYTListVideosView(listType: .mostPopular)
            } label: {
                HStack(spacing: 20) {
                    Image(systemName: "star.square.fill")
                        .foregroundColor(.gray)
                    
                    Text("Popular videos")
                        .appFont()
                }
                .frame(height: 40)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            }
            .id("star.square.fill")
            
            NavigationLink {
                TPYTListVideosView(listType: .historyVideo)
            } label: {
                HStack(spacing: 20) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.gray)
                    
                    Text("App history")
                        .appFont()
                }
                .frame(height: 40)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
            }
            .id("clock.fill")
            
            Text("Playlist")
                .appFont(20, weight: .medium)
                .frame(height: 45, alignment: .bottom)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 2, trailing: 0))
                .id("Playlist_Row")
            
            switch vm.state {
            case .getting:
                VStack {
                    ProgressView()
                }
                .id("ProgressView_Row")
                .listRowSeparator(.hidden, edges: .bottom)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            case .done(_):
                ForEach(vm.playlist, id: \.id) {
                    item in
                    NavigationLink {
                        TPYTListVideosView(listType: .playListVideos(playList: item))
                    } label: {
                        HStack(spacing: 16) {
                            CachedAsyncImage(url: URL(string: item.snippet.thumbnails.default.url)!) {
                                image in
                                image
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 4)
                                    .foregroundColor(Color(uiColor: UIColor.darkGray))
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.snippet.title)
                                    .appFont()
                                if item.contentDetails.itemCount != 0 {
                                    Text(item.contentDetails.itemCount > 1 ? "\(item.contentDetails.itemCount) videos" : "\(item.contentDetails.itemCount) video")
                                        .appFont(12)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .frame(height: 45)
                    }
                    .id(item)
                }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .alignmentGuide(.listRowSeparatorLeading) {
            viewDimensions in
            return 0
        }
        .onAppear {
            vm.getPlaylistForFirstTimeAppear()
        }
    }
}

struct TPYTPlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        TPYTPlaylistView()
            .environmentObject(TPGGAuthManager())
    }
}
