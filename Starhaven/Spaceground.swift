//
//  Spaceground.swift
//  Starhaven
//
//  Created by JxR on 4/4/23.
//

import Foundation
import SwiftUI
import SceneKit
import simd

struct ContentView: View {
    var body: some View {
        VStack {
            SpacecraftView()
        }
    }
}
struct SpacecraftView: View {
    @StateObject var spacecraftViewModel = SpacecraftViewModel()
    
    var body: some View {
        Space()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        spacecraftViewModel.dragChanged(value: value)
                    }
                    .onEnded { _ in
                        spacecraftViewModel.dragEnded()
                    }
            )
            .overlay(
                HUDView()
                    .environmentObject(spacecraftViewModel)
            )
            .environmentObject(spacecraftViewModel)
        Slider(value: $spacecraftViewModel.ship.throttle, in: 0...10, step: 0.1)
            .padding()
    }
}

struct Space: UIViewRepresentable {
    @EnvironmentObject var spaceViewModel: SpacecraftViewModel
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIView(context: Context) -> SCNView {
        return self.spaceViewModel.makeSpaceView()
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // ...
    }

    class Coordinator: NSObject {
        var view: Space

        init(_ view: Space) {
            self.view = view
        }
    }
}
class SpacecraftViewModel: ObservableObject {
    @Published var previousTranslation: CGSize = CGSize.zero
    @Published var currentRotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    @Published var view: SCNView = SCNView()
    @Published var scene: SCNScene = SCNScene()
    @Published var ship = Ship()
    @Published var cameraNode: SCNNode!
    @Published var blackHoles: [BlackHole] = []
    @Published var isInverted: Bool = false
    @Published var rotationDeltaX: Float = 0
    @Published var rotationDeltaY: Float = 0
    @Published var isDragging: Bool = false
    @Published var rotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var isRotationActive: Bool = false

    init() {
        self.setupCamera()
        // Create a timer to update the ship's position
        Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            self.updateShipPosition()
        }
    }
    public func makeSpaceView() -> SCNView {
        let scnView = SCNView()
        scnView.scene = self.scene
        // Load spacecraftNode and add it to the scene
        let modelPath = Bundle.main.path(forResource: "fish", ofType: "obj", inDirectory: "SceneKit Asset Catalog.scnassets")!
        let url = NSURL(fileURLWithPath: modelPath)
        let asset = MDLAsset(url:url as URL)
        let object = asset.object(at: 0)
        var node = SCNNode(mdlObject: object)
        self.ship.shipNode = node
        scnView.scene?.rootNode.addChildNode(self.cameraNode) // Add this line
        scnView.scene?.rootNode.addChildNode(self.ship.shipNode)
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.black
        scnView.scene?.background.contents = [
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7"),
            UIImage(named: "stars7")
        ]
        self.scene.background.intensity = 0.33
        Task {
            self.blackHoles.append(self.addBlackHole(radius: 20, ringCount: 22, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 50, ringCount: 12, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 15, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 3, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 5, ringCount: 2, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 60, ringCount: 18, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 5, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
        }
        return scnView
    }
    
    // WORLD SET-UP
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: self.ship.shipNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe)
        self.scene.rootNode.addChildNode(blackHole.blackHoleNode)
        blackHole.blackHoleNode.worldPosition = SCNVector3(x: Float.random(in: -1000...1000), y:Float.random(in: -1000...1000), z: Float.random(in: -1000...1000))
        blackHole.blackHoleNode.renderingOrder = 0
        return blackHole
    }
    
    // PILOT NAV
    func updateShipOrientation() {
        let worldUp = SIMD3<Float>(0, 1, 0)
        let shipUp = ship.shipNode.presentation.simdWorldUp

        // Calculate the dot product of the ship's up vector and the world's up vector
        let dotProduct = simd_dot(shipUp, worldUp)

        if dotProduct < 0 {
            DispatchQueue.main.async {
                self.isInverted = true
            }
        } else {
            DispatchQueue.main.async {
                self.isInverted = false
            }
        }

        let shipQuaternion = ship.shipNode.presentation.orientation
        let eulerAngles = quaternionToEulerAngles(shipQuaternion)

        DispatchQueue.main.async {
            self.ship.yaw = CGFloat(eulerAngles.x * 180 / Float.pi)
            self.ship.pitch = CGFloat(eulerAngles.y * 180 / Float.pi)
            self.ship.roll = CGFloat(eulerAngles.z * 180 / Float.pi)
        }
    }
    func updateShipPosition() {
        applyRotation() // Add this line

        ship.shipNode.simdPosition += ship.shipNode.simdWorldFront * ship.throttle

        let distance: Float = 15.0 // Define the desired distance between the camera and the spaceship
        let cameraPosition = ship.shipNode.simdPosition - (ship.shipNode.simdWorldFront * distance)
        cameraNode.simdPosition = cameraPosition
        cameraNode.simdOrientation = ship.shipNode.simdOrientation
        // Update the look-at constraint target
        cameraNode.constraints = [createLookAtConstraint()]
        self.updateShipOrientation()
    }
    func throttle(value: Float) {
        ship.throttle = value
    }
    func dragChanged(value: DragGesture.Value) {
        let translation = value.translation
        let deltaX = Float(translation.width - previousTranslation.width) * 0.01
        let deltaY = Float(translation.height - previousTranslation.height) * 0.01

        let dampeningFactor: Float = 0.1 // Adjust this value to increase or decrease the dampening effect
        rotationVelocity.x = deltaX * dampeningFactor
        rotationVelocity.y = deltaY * dampeningFactor

        previousTranslation = translation
        isRotationActive = true
    }
    func dragEnded() {
        previousTranslation = CGSize.zero
        isRotationActive = false
    }
    func applyRotation() {
        if isRotationActive {
            let adjustedDeltaX = isInverted ? -rotationVelocity.x : rotationVelocity.x

            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: SIMD3<Float>(0, 1, 0))
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: rotationVelocity.y, axis: cameraRight)

            let totalRotation = simd_mul(rotationY, rotationX)

            currentRotation = simd_mul(totalRotation, currentRotation)
            ship.shipNode.simdOrientation = currentRotation
        }
    }

    func createLookAtConstraint() -> SCNLookAtConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: ship.shipNode)
        lookAtConstraint.influenceFactor = 1
        return lookAtConstraint
    }
    func setupCamera() {
        // Create a camera
        let camera = SCNCamera()
        camera.zFar = 100000
        
        // Create a camera node and attach the camera
        self.cameraNode = SCNNode()
        self.cameraNode.camera = camera
        
        // Position the camera node relative to the spacecraft
        self.cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
        

        // Add a look-at constraint to the camera node
        cameraNode.constraints = [createLookAtConstraint()]
    }
    func worldQuaternionToEulerAngles(_ node: SCNNode) -> SCNVector3 {
        let worldOrientation = node.presentation.simdWorldOrientation
        let matrix = simd_float3x3(worldOrientation)
        
        let sy = sqrt(matrix[0][0] * matrix[0][0] + matrix[1][0] * matrix[1][0])
        let singular = sy < 1e-6
        
        var x, y, z: Float
        if !singular {
            x = atan2(matrix[2][1], matrix[2][2])
            y = atan2(-matrix[2][0], sy)
            z = atan2(matrix[1][0], matrix[0][0])
        } else {
            x = atan2(-matrix[1][2], matrix[1][1])
            y = atan2(-matrix[2][0], sy)
            z = 0
        }
        print(x, y, z)
        return SCNVector3(x, y, z)
    }

    func quaternionToEulerAngles(_ quaternion: SCNQuaternion) -> SCNVector3 {
        let q = simd_quatf(ix: quaternion.x, iy: quaternion.y, iz: quaternion.z, r: quaternion.w)
        let matrix = simd_float3x3(q)
        
        let sy = sqrt(matrix[0][0] * matrix[0][0] + matrix[1][0] * matrix[1][0])
        let singular = sy < 1e-6
        
        var x, y, z: Float
        if !singular {
            x = atan2(matrix[2][1], matrix[2][2])
            y = atan2(-matrix[2][0], sy)
            z = atan2(matrix[1][0], matrix[0][0])
        } else {
            x = atan2(-matrix[1][2], matrix[1][1])
            y = atan2(-matrix[2][0], sy)
            z = 0
        }
        return SCNVector3(x, y, z)
    }
}
class Ship: ObservableObject {
    @Published var shipNode: SCNNode = SCNNode()
    @Published var pitch: CGFloat = 0
    @Published var yaw: CGFloat = 0
    @Published var roll: CGFloat = 0
    @Published var throttle: Float = 0
}
struct HUDView: View {
    @EnvironmentObject var spacecraftViewModel: SpacecraftViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Yaw: \(spacecraftViewModel.ship.yaw, specifier: "%.2f")")
                Spacer()
                Text("Pitch: \(spacecraftViewModel.ship.pitch, specifier: "%.2f")")
                Spacer()
                Text("Roll: \(spacecraftViewModel.ship.roll, specifier: "%.2f")")
            }
            .foregroundColor(.blue)
            Spacer()
            if spacecraftViewModel.isInverted {
                Text("INVERTED")
                    .foregroundColor(.red)
                    .bold()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            spacecraftViewModel.isInverted = false
                        }
                    }
            }
            Spacer()
            Reticle()
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
        }.padding()
    }
}

struct Reticle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let innerRadius: CGFloat = 5
        let outerRadius: CGFloat = 15

        let points = [
            CGPoint(x: center.x, y: center.y - innerRadius),
            CGPoint(x: center.x, y: center.y - outerRadius),
            CGPoint(x: center.x, y: center.y + innerRadius),
            CGPoint(x: center.x, y: center.y + outerRadius),
            CGPoint(x: center.x - innerRadius, y: center.y),
            CGPoint(x: center.x - outerRadius, y: center.y),
            CGPoint(x: center.x + innerRadius, y: center.y),
            CGPoint(x: center.x + outerRadius, y: center.y),
        ]

        path.move(to: points[0])
        path.addLine(to: points[1])
        path.move(to: points[2])
        path.addLine(to: points[3])
        path.move(to: points[4])
        path.addLine(to: points[5])
        path.move(to: points[6])
        path.addLine(to: points[7])

        return path
    }
}
