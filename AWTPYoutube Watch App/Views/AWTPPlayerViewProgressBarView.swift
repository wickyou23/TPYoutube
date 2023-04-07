//
//  AWTPPlayerViewProgressBarView.swift
//  AWTPYoutube Watch App
//
//  Created by Thang Phung on 06/04/2023.
//

import Foundation
import SwiftUI

struct AWTPPlayerViewProgressBarView: View {
    @EnvironmentObject private var theme: TPTheme
    @StateObject private var vm = AWTPPlayerViewProgressBarViewModel()
    
    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .foregroundColor(theme.appColor)
                        .frame(width: vm.progressValue * geo.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
        }
        .frame(height: 3)
    }
}

struct AWTPPlayerViewProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        AWTPPlayerViewProgressBarView()
            .environmentObject(TPTheme.shared)
    }
}
