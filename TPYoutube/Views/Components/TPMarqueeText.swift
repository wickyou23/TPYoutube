//
//  TPMarqeeText.swift
//  TPYoutube
//
//  Created by Thang Phung on 08/03/2023.
//

import Foundation
import SwiftUI
import Combine

struct TPMarqueeText: View {
    #if os(iOS)
    @StateObject private var vm = _TPMarqueeTextViewModel()
    #endif
    
    private let text: String?
    private let attributeText: AttributedString?
    
    let uiFont: UIFont
    let startDelay: Double
    let manualAnimation: Bool
    var isCompact = false
    
    @State private var textAnimate = false
    @State private var stringSize = CGSize.zero
    @State private var animation: Animation = .linear(duration: 0)
    
    private let nullAnimation = Animation.linear(duration: 0).speed(0)
    private let leftFade: CGFloat = 8
    private let rightFade: CGFloat = 8
    private var isAnimated: Bool {
        #if os(iOS)
        return manualAnimation && textAnimate && !vm.keyboardIsVisible
        #else
        return manualAnimation && textAnimate
        #endif
    }
    
    @ViewBuilder
    private var mText: some View {
        if let attributeText = attributeText {
            Text(attributeText)
        }
        else if let stringText = text {
            Text(stringText)
        }
        else {
            Text("")
        }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geo in
                if stringSize.width > geo.size.width {
                    Group {
                        mText
                            .lineLimit(1)
                            .font(.init(uiFont))
                            .offset(x: isAnimated ? -stringSize.width - stringSize.height * 2 : 0)
                            .animation(isAnimated ? animation : nullAnimation, value: isAnimated)
                            .onAppear {
                                DispatchQueue.main.async {
                                    textAnimate = geo.size.width < stringSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                        
                        mText
                            .lineLimit(1)
                            .font(.init(uiFont))
                            .offset(x: isAnimated ? 0 : stringSize.width + stringSize.height * 2)
                            .animation(isAnimated ? animation : nullAnimation, value: isAnimated)
                            .onAppear {
                                DispatchQueue.main.async {
                                    textAnimate = geo.size.width < stringSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .onValueChanged(of: text, perform: { text in
                        textAnimate = geo.size.width < stringSize.width
                    })
                    .offset(x: leftFade)
                    .mask(
                        HStack(spacing:0) {
                            Rectangle()
                                .frame(width:2)
                                .opacity(0)
                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
                                .frame(width:leftFade)
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/)
                                .frame(width:rightFade)
                            Rectangle()
                                .frame(width:2)
                                .opacity(0)
                        })
                    .frame(width: geo.size.width + leftFade)
                    .offset(x: leftFade * -1)
                } else {
                    mText
                        .font(.init(uiFont))
                        .onValueChanged(of: self.text, perform: {text in
                            textAnimate = geo.size.width < stringSize.width
                        })
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(height: stringSize.height)
        .frame(maxWidth: isCompact ? stringSize.width : nil)
        .onDisappear { textAnimate = false }
        .onAppear {
            DispatchQueue.main.async {
                var mStringSize: CGSize = .zero
                if let attributeText = attributeText {
                    let stringText = NSAttributedString(attributeText).string
                    mStringSize = stringText.sizeOfString(usingFont: uiFont)
                }
                else if let stringText = text {
                    mStringSize = stringText.sizeOfString(usingFont: uiFont)
                }
                
                stringSize = mStringSize
                animation = Animation
                    .linear(duration: Double(mStringSize.width) / 30)
                    .delay(startDelay)
                    .repeatForever(autoreverses: false)
            }
        }
        
    }
    
    init(text: String, uiFont: UIFont, startAnimation: Bool, startDelay: Double, alignment: Alignment? = nil) {
        self.text = text
        self.attributeText = nil
        self.uiFont = uiFont
        self.startDelay = startDelay
        self.manualAnimation = startAnimation
    }
    
    init(text: AttributedString, startAnimation: Bool, startDelay: Double, alignment: Alignment? = nil) {
        let nsAttr = NSAttributedString(text)
        let attrFont = nsAttr.attribute(.font, at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: nsAttr.length))
        
        self.uiFont = (attrFont as? UIFont) ?? TPTheme.shared.appUIFont()
        self.startDelay = startDelay
        self.text = nil
        self.attributeText = text
        self.manualAnimation = startAnimation
    }
}

extension TPMarqueeText {
    public func makeCompact(_ compact: Bool = true) -> Self {
        var view = self
        view.isCompact = compact
        return view
    }
}

fileprivate extension String {
    func sizeOfString(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size
    }
}

fileprivate extension View {
    @ViewBuilder func onValueChanged<T: Equatable>(of value: T, perform onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            self.onReceive(Just(value)) { (value) in
                onChange(value)
            }
        }
    }
}

#if os(iOS)
fileprivate class _TPMarqueeTextViewModel: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardIsVisible = false
    
    private var keyboardCancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default
            .publisher(for: UIWindow.keyboardWillShowNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let userInfo = notification.userInfo else { return }
                guard let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                
                self.keyboardIsVisible = keyboardFrame.minY < UIScreen.main.bounds.height
                self.keyboardHeight = self.keyboardIsVisible ? keyboardFrame.height : 0
            }
            .store(in: &keyboardCancellables)
        
        NotificationCenter.default
            .publisher(for: UIWindow.keyboardDidHideNotification)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                self.keyboardIsVisible = false
                self.keyboardHeight = 0
            }
            .store(in: &keyboardCancellables)
    }
}
#endif

struct TPMarqueeText_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var isPresented = true

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    Color.clear
                    VStack {
                        TPMarqueeText(text: "If you have a bug or an idea, browse the open issues before opening a new one. You can also take a look at the Open", startAnimation: true, startDelay: 3)
                    }
                }
                .environmentObject(TPTheme.shared)
                #if os(iOS)
                .environmentObject(TPYTPlayerManager.shared)
                #endif
            }
        }
    }
}
