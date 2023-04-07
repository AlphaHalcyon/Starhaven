//
//  ContentView.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//

import SwiftUI
import SceneKit

@MainActor struct CntentView: View {
    @StateObject var viewModel: SpaceViewModel = SpaceViewModel()
    @State private var xRotation: Float = 0
    @State private var yRotation: Float = 0
    @State private var throttleValue: Float = 0
    @State private var timer: Timer?
    
    var body: some View {
        let longPressDragGesture = LongPressGesture(minimumDuration: 0.001)
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press gesture is recognized
                    timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                        self.viewModel.pilot.cameraNode.eulerAngles.y += yRotation/1000
                        self.viewModel.pilot.cameraNode.eulerAngles.x -= xRotation/1000
                    }
                case .second(true, let drag):
                    // Drag gesture is recognized after long press gesture
                    let translation = drag?.translation ?? .zero
                    let xTranslation = Float(translation.width)
                    let yTranslation = Float(-translation.height)
                    
                    // Use the pan translation along the x axis to adjust the camera's rotation about its y axis
                    yRotation = xTranslation * .pi / 180.0
                    
                    // Use the pan translation along the y axis to adjust the camera's rotation about its x axis
                    xRotation = yTranslation * .pi / 180.0
                    print(xRotation, yRotation)
                    // Update the camera's orientation
                    self.viewModel.pilot.cameraNode.eulerAngles.y += yRotation/1000
                    self.viewModel.pilot.cameraNode.eulerAngles.x -= xRotation/1000
                    print(self.viewModel.pilot.cameraNode.eulerAngles)
                    print(self.viewModel.pilot.pilotNode.eulerAngles)
                    print(self.viewModel.pilot.containerNode.eulerAngles)
                default:
                    break
                }
            }
            .onEnded { _ in
                // Stop updating the camera's orientation when the long press gesture is over
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Invalidate the timer after a delay of 0.3 seconds
                    timer?.invalidate()
                    timer = nil
                    xRotation = 0
                    yRotation = 0
                }
            }
        let panGesture = DragGesture()
            .onChanged { value in
                let normalizedTranslation = max(0, min(1, -value.translation.height / 100))
                self.throttleValue = Float(normalizedTranslation)
                print("recognized \(self.throttleValue)")
            }

        let throttleView = ZStack {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 225 * CGFloat(throttleValue))
                    }
                    .frame(width: 75, height: 225).opacity(0.1)
                    VStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 225)
                        Spacer()
                    }
                    .frame(width: 75, height: 225).opacity(0.15)
                }
                .frame(width: 75, height: 225)
                .highPriorityGesture(panGesture)

        return ZStack {
            SpaceView(throttleValue: self.$throttleValue).simultaneousGesture(longPressDragGesture).environmentObject(self.viewModel)
                
                
                // Reticle view
                Circle()
                .fill(Color.cyan.opacity(0.5))
                    .frame(width: 15, height: 15)
            VStack {
                Spacer()
                HStack {
                    throttleView.zIndex(100)
                    Spacer()
                }
            }
        }
    }

}
