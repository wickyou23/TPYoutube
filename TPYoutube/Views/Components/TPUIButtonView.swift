//
//  TPUIButtonView.swift
//  TPYoutube
//
//  Created by Thang Phung on 10/03/2023.
//

import Foundation
import SwiftUI

struct UIButtonViewModifier: ViewModifier {
    let touchDownAction: () -> Void
    let touchUpInsideAction: () -> Void
    let touchCancelAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay {
                UIButtonView(touchDownAction: touchDownAction,
                             touchUpInsideAction: touchUpInsideAction,
                             touchCancelAction: touchCancelAction)
            }
    }
}

struct UIButtonView: UIViewRepresentable {
    let touchDownAction: () -> Void
    let touchUpInsideAction: () -> Void
    let touchCancelAction: () -> Void
    
    func makeUIView(context: Context) -> some UIView {
        let button = UIButton(frame: .zero)
        
        button.addTarget(context.coordinator, action: #selector(context.coordinator.handleTouchDown(_:)), for: .touchDown)
        button.addTarget(context.coordinator, action: #selector(context.coordinator.handleTouchUpInside(_:)), for: .touchUpInside)
        button.addTarget(context.coordinator, action: #selector(context.coordinator.handleTouchCancel(_:)), for: .touchCancel)
        
        return button
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    func makeCoordinator() -> UIButtonViewCoordinator {
        UIButtonViewCoordinator(touchDownAction: touchDownAction,
                                touchUpInsideAction: touchUpInsideAction,
                                touchCancelAction: touchCancelAction)
    }
}

class UIButtonViewCoordinator {
    let touchDownAction: () -> Void
    let touchUpInsideAction: () -> Void
    let touchCancelAction: () -> Void
    
    init(touchDownAction: @escaping () -> Void,
         touchUpInsideAction: @escaping () -> Void,
         touchCancelAction: @escaping () -> Void) {
        self.touchDownAction = touchDownAction
        self.touchUpInsideAction = touchUpInsideAction
        self.touchCancelAction = touchCancelAction
    }
    
    @objc func handleTouchDown(_ button: UIButton) {
        touchDownAction()
    }
    
    @objc func handleTouchUpInside(_ button: UIButton) {
        touchUpInsideAction()
    }
    
    @objc func handleTouchCancel(_ button: UIButton) {
        touchCancelAction()
    }
}
