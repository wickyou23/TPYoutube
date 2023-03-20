//
//  TPSlider.swift
//  TPYoutube
//
//  Created by Thang Phung on 28/02/2023.
//

import Foundation
import SwiftUI

struct TPSlider: View {
    @Binding var value: Float
    
    var minValue: Float
    var maxValue: Float
    var onDragging: (Float) -> Void
    var onEnded: (Float) -> Void
    
    @State private var dragLocation: CGPoint?
    @State private var isSliderDragging: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: geo.size.height / 2, style: .circular)
                        .mask({
                            RoundedRectangle(cornerRadius: geo.size.height / 2, style: .circular)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .border(Color.white)
                        })
                        .foregroundColor(Color(uiColor: .white.withAlphaComponent(0.8)))
                        .frame(width: getSliderWidth(geo), height: geo.size.height)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                .background(Color(uiColor: .gray))
                .cornerRadius(geo.size.height / 2)
            }
            .frame(height: geo.size.height)
            .gesture(DragGesture(minimumDistance: 0).onChanged({
                dragValue in
                iLog("Draging \(dragValue.location)")
                let calValue = CGFloat(minValue) + ((dragValue.location.x * CGFloat((maxValue - minValue))) / geo.size.width)
                value = Float(calValue)
                onDragging(value)
                
                dragLocation = dragValue.location
            }).onEnded({
                endValue in
                iLog("End \(endValue.location)")
                let calValue = CGFloat(minValue) + ((endValue.location.x * CGFloat((maxValue - minValue))) / geo.size.width)
                value = Float(calValue)
                onEnded(value)
                
                dragLocation = nil
            }))
        }
    }
    
    private func getSliderWidth(_ geo: GeometryProxy) -> Double {
        if maxValue == 0 {
            return 0
        }
        
        if let dragLocation = self.dragLocation {
            return dragLocation.x
        }
        
        return geo.size.width * CGFloat(min((value / (maxValue - minValue)), maxValue))
    }
}


struct TPSlider_Previews: PreviewProvider {
    static var previews: some View {
        TPSlider(value: .constant(10), minValue: 0, maxValue: 100) {
            dragValue in
            
        } onEnded: {
            endValue in
            
        }
        .frame(height: 14)
    }
}
