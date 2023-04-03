//
//  TPYTHelper.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import Combine
import SwiftUI
import CocoaLumberjackSwift

#if os(iOS)
import UIKit
import Moya
#endif

@inlinable func eLog(_ items: Any, functionName: String = #function) {
    DDLogError("🔴 [\(functionName)] \(items)")
}

@inlinable func sLog(_ items: Any, functionName: String = #function) {
    DDLogVerbose("🟢 [\(functionName)] \(items)")
}

@inlinable func iLog(_ items: Any, functionName: String = #function) {
    DDLogInfo("🐛 [\(functionName)] \(items)")
}

//MARK: - TPHelper

struct TPHelper {
    #if os(iOS)
    fileprivate static var keyboardObserver: AnyPublisher<Bool, Never> {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIWindow.keyboardWillShowNotification)
            .compactMap { _ in
                return true
            }
        
        let keyboardWillHide = NotificationCenter.default.publisher(for: UIWindow.keyboardWillHideNotification)
            .compactMap { _ in
                return false
            }
        
        return Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .eraseToAnyPublisher()
    }
    #endif
}

//MARK: - Extension

enum ISO8601DateError: String, Error {
    case invalidISO8601Date
}

extension Date {
    static var currentDayOfWeek: Int {
        get {
            return Calendar.current.component(.weekday, from: Date())
        }
    }
    
    static func getISO8601DateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateStr) else {
                throw ISO8601DateError.invalidISO8601Date
            }
            
            return date
        }
    }
    
    static func getISO8601DateEncodingStrategy() -> JSONEncoder.DateEncodingStrategy {
        return .custom { (date, encoder) in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let stringData = formatter.string(from: date)
            var container = encoder.singleValueContainer()
            try container.encode(stringData)
        }
    }
    
    init(iso8601String:String) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.calendar =  Calendar(identifier: Calendar.Identifier.iso8601)
        
        var d = dateFormatter.date(from: iso8601String)
        
        if d == nil {
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        }
        
        d = dateFormatter.date(from: iso8601String)
        
        self.init(timeInterval:0, since:d!)
    }
    
    var timeAgo: String {
        
        let now = Date()
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .weekOfYear, .day, .hour, .minute, .second],
            from: self,
            to: now
        )
        
        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") ago"
        }
        
        if let months = components.month, months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") ago"
        }
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        }
        if let days = components.day, days > 0 {
            guard days > 1 else { return "yesterday" }
            
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
        
        if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
        
        if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }
        
        if let seconds = components.second, seconds > 30 {
            return "\(seconds) second\(seconds == 1 ? "" : "s") ago"
        }
        
        return "just now"
    }
}

// URLCache+imageCache.swift

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 100*1024*1024, diskCapacity: 200*1024*1024)
}

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension String {
    var doubleValue: Double? {
        Double(self)
    }
    
    func decodeStringToHTMLAttribute(uiFont: UIFont, color: Color? = nil) -> AttributedString? {
        guard let data = self.data(using: .utf8),
              let htmlDecoded = try? NSMutableAttributedString(data: data, options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
              ], documentAttributes: nil) else {
            return nil
        }
        
        let primaryColor = UIColor(color ?? Color.primary)
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = .byTruncatingTail
        para.lineSpacing = 0
        
        htmlDecoded.addAttributes([.font: uiFont, .paragraphStyle: para, .foregroundColor: primaryColor], range: NSRange(location: 0, length: htmlDecoded.length))
        return AttributedString(htmlDecoded)
    }
}

extension Double {
    private func reduceScale(to places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        let newDecimal = multiplier * self // move the decimal right
        let truncated = Double(Int(newDecimal)) // drop the fraction
        let originalDecimal = truncated / multiplier // move the decimal back
        return originalDecimal
    }
    
    func formatNumber() -> String {
        let num = abs(self)
        let sign = (self < 0) ? "-" : ""
        switch num {
        case 1_000_000_000...:
            var formatted = num / 1_000_000_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)B"
        case 1_000_000...:
            var formatted = num / 1_000_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)M"
        case 1_000...:
            var formatted = num / 1_000
            formatted = formatted.reduceScale(to: 1)
            return "\(sign)\(formatted)K"
        case 0...:
            return "\(self)"
        default:
            return "\(sign)\(self)"
        }
    }
}

//class ViewReference<T: UIView> {
//    weak var view: T?
//}


extension Animation {
    static func nullAnimation() -> Animation {
        Animation.linear(duration: 0).speed(0)
    }
}

//MARK: - iOS Extension

#if os(iOS)
extension Publisher {
    func mapMoyaError() -> Publishers.MapError<Self, MoyaError> {
        return self.mapError({
            guard let moyaError = $0 as? MoyaError else {
                return MoyaError.underlying($0, nil)
            }
            
            return moyaError
        })
    }
}

extension UIApplication {
    var tpKeyWindow: UIWindow? {
        let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
        return keyWindow
    }
    
    static func topMostController() -> UIViewController? {
        guard let window = Self.shared.keyWindow,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        
        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
}

extension UIImage {
    static func gradientImageWithBounds(bounds: CGRect, colors: [CGColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    static func getImageCached(from request: URLRequest) -> UIImage? {
        guard let cachedResponse = URLCache.imageCache.cachedResponse(for: request),
                let image = UIImage(data: cachedResponse.data) else { return nil }
        return image
    }
    
    func getAverageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension View {
    func onKeyboardObserver(_ action: @escaping (Bool) -> Void) -> some View {
        return self.onReceive(TPHelper.keyboardObserver) { value in
            action(value)
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
