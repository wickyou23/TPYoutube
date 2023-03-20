//
//  TPPopupView.swift
//  TPYoutube
//
//  Created by Thang Phung on 06/03/2023.
//

import Foundation
import SwiftUI

struct Popup: ViewModifier {
    @EnvironmentObject private var theme: TPTheme
    
    let isPresented: Binding<Bool>
    let title: String
    let message: String
    let okAction: (() -> Void)?
    
    let screenSize = UIScreen.main.bounds
    
    init(isPresented: Binding<Bool>, title: String, message: String, okAction: @escaping (() -> Void)) {
        self.isPresented = isPresented
        self.title = title
        self.message = message
        self.okAction = okAction
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(popupContent())
    }
    
    @ViewBuilder private func popupContent() -> some View {
        if isPresented.wrappedValue {
            ZStack(content: {
                VStack(spacing: 0) {
                    Text(title)
                        .appFont(20, weight: .medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(theme.popupBgTitleColor)
                    Text(message)
                        .appFont()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 30, leading: 16, bottom: 30, trailing: 16))
                    Divider()
                    HStack {
                        Button {
                            isPresented.wrappedValue = false
                        } label: {
                            Text("Cancle")
                                .appFont()
                                .foregroundColor(.gray)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        
                        Divider()
                        
                        Button {
                            isPresented.wrappedValue = false
                            DispatchQueue.main.async {
                                okAction?()
                            }
                        } label: {
                            Text("OK")
                                .appFont()
                                .fontWeight(.medium)
                                .foregroundColor(theme.appColor)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 50)
                }
                .frame(width: screenSize.width * 0.8, alignment: .leading)
                .background(.white)
                .cornerRadius(8)
            })
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            .frame(width: screenSize.width, height: screenSize.height)
            .background(.gray.opacity(0.7))
        }
    }
}

struct Popup_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
    
    struct Preview: View {
        @State var isPresented = false
        
        var body: some View {
            VStack {
                Button {
                    isPresented.toggle()
                } label: {
                    Text("Show Popup")
                }
            }
            .modifier(Popup(isPresented: $isPresented, title: "Logout", message: "Do you want to logout?", okAction: {
                
            }))
            .environmentObject(TPTheme())
        }
    }
}

