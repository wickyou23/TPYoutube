//
//  TPTheme.swift
//  TPYoutube
//
//  Created by Thang Phung on 02/03/2023.
//

import Foundation
import SwiftUI

class TPTheme: ObservableObject {
    static var shared = TPTheme()
    
    @Published private(set) var fontName = "futura"
    @Published private(set) var appColor = Color(hex: 0xff5252)
    
    var popupBgTitleColor: Color {
        appColor.opacity(0.8)
    }
    
    func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom(fontName, size: size).weight(weight)
    }
    
    func appFont(_ size: CGFloat, style: Font.TextStyle) -> Font {
        return Font.custom(fontName, size: size, relativeTo: style)
    }
    
    func appFontStyle(_ style: Font.TextStyle) -> Font {
        let styleFont = UIFont.preferredFont(from: style)
        return TPTheme.shared.appFont(styleFont.pointSize, style: style)
    }
    
    func appUIFont() -> UIFont {
        let styleFont = UIFont.preferredFont(forTextStyle: .body)
        return UIFont(name: fontName, size: styleFont.pointSize)!
    }
    
    func appUIFont(_ style: Font.TextStyle, weight: Font.Weight) -> UIFont {
        let styleFont = UIFont.preferredFont(from: style)
        return UIFont(name: getFontNameWithWeight(weight), size: styleFont.pointSize)!
    }
    
    private func getFontNameWithWeight(_ weight: Font.Weight) -> String {
        switch weight {
        case .medium:
            return fontName + "-medium"
        case .bold:
            return fontName + "-bold"
        default:
            return fontName
        }
    }
}

extension View {
    func appFont() -> some View {
        self.appFontStyle(.body).fontWeight(.regular)
    }
    
    func appFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(TPTheme.shared.appFont(size, weight: weight))
    }
    
    func appFontWeight(_ weight: Font.Weight) -> some View {
        self.appFont().fontWeight(weight)
    }
    
    func appFontStyle(_ style: Font.TextStyle) -> some View {
        return self.font(TPTheme.shared.appFontStyle(style))
    }
}

fileprivate extension UIFont {
    class func preferredFont(from textStyle: Font.TextStyle) -> UIFont {
        let uiFont: UIFont
        
        switch textStyle {
        case .largeTitle:
            uiFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            uiFont = UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            uiFont = UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            uiFont = UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            uiFont = UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            uiFont = UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:
            uiFont = UIFont.preferredFont(forTextStyle: .callout)
        case .caption:
            uiFont = UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            uiFont = UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:
            uiFont = UIFont.preferredFont(forTextStyle: .footnote)
        case .body:
            fallthrough
        default:
            uiFont = UIFont.preferredFont(forTextStyle: .body)
        }
        
        return uiFont
    }
}
