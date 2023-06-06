//
//  Custom Slider.swift
//  Starhaven
//
//  Created by JxR on 5/9/23.
//

import Foundation
import SwiftUI

struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onChange: (Float) -> Void
    let width: CGFloat = 45
    let height: CGFloat = 225
    
    @State private var isDragging = false
    private let debounceInterval = DispatchTimeInterval.milliseconds(16)
    @State var debounceWorkItem: DispatchWorkItem?
    
    private func debounce(_ action: @escaping () -> Void) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem(block: action)
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                let verticalGradient = LinearGradient(gradient: Gradient(colors: [.red, .cyan, .red]), startPoint: .bottom, endPoint: .top)
                let sliderY = (1 - CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))) * height
                
                verticalGradient
                    .cornerRadius(3)
                    .overlay(
                        Rectangle()
                            .frame(width: width, height: 5)
                            .position(x: width / 2, y: sliderY)
                            .foregroundColor(.white)
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gestureValue in
                                DispatchQueue.main.async {
                                    isDragging = true
                                    let newValue = Float(1 - gestureValue.location.y / height)
                                    let clampedValue = min(max(newValue, 0), 1)
                                    let mappedValue = clampedValue * (range.upperBound - range.lowerBound) + range.lowerBound
                                    value = mappedValue
                                    debounce {
                                        onChange(mappedValue)
                                        isDragging = false
                                    }
                                }
                            }
                    )
                    .opacity(0.66)
            }
        }
        .frame(width: width, height: height)
        .rotation3DEffect(
            Angle(degrees: 180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .padding()
    }
}

