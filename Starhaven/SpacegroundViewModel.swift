//
//  SpacegroundViewModel.swift
//  Starhaven
//
//  Created by JxR on 4/6/23.
//

import Foundation
import SwiftUI
import SceneKit
import simd

@MainActor class SpacecraftViewModel: ObservableObject {
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
    @Published var isPressed: Bool = false
    @Published var longPressTimer: Timer = Timer()
    @Published var averageRotationVelocity: SIMD2<Float> = SIMD2<Float>(0, 0)
    @Published var rotationVelocityBufferX: VelocityBuffer
    @Published var rotationVelocityBufferY: VelocityBuffer
    @Published var closestBlackHole: BlackHole?
    @Published var distanceToBlackHole: CGFloat = .greatestFiniteMagnitude
    @Published var points: Int = 0
    @Published var showScoreIncrement: Bool = false
    init() {
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 10)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 10)
        self.setupCamera()
        // Create a timer to update the ship's position
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
                self.updateShipPosition()
            }
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
        Task {
            self.scene.background.intensity = 0.33
            self.blackHoles.append(self.addBlackHole(radius: 20, ringCount: 10, vibeOffset: 1, bothRings: true, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 1000, ringCount: 8, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 12, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 6, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 5, ringCount: 5, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 60, ringCount: 7, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 8, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 25, ringCount: 8, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 250, ringCount: 9, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh))
            self.blackHoles.append(self.addBlackHole(radius: 150, ringCount: 5, vibeOffset: 1, bothRings: false, vibe: ShaderVibe.discOh))
        }
        let blackHole = self.addBlackHole(radius: 60, ringCount: 7, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh)
        let redStar = Star(radius: 250, color: UIColor.red)
        redStar.starNode.position = SCNVector3(1500, 0, 0)
        blackHole.blackHoleNode.addChildNode(redStar.starNode)
        for hole in blackHoles {
            scnView.prepare(hole)
        }
        scnView.prepare(blackHole.blackHoleNode)
        scnView.prepare(redStar.starNode)
        scnView.prepare(self.scene)
        return scnView
    }
    
    // WORLD SET-UP
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: self.ship.shipNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe)
        self.scene.rootNode.addChildNode(blackHole.blackHoleNode)
        blackHole.blackHoleNode.worldPosition = SCNVector3(x: Float.random(in: -5000...5000), y:Float.random(in: -5000...5000), z: Float.random(in: -5000...5000))
        blackHole.blackHoleNode.renderingOrder = 0
        return blackHole
    }
    // PILOT NAV
    func applyRotation() {
        if isRotationActive {
            let adjustedDeltaX = isInverted ? -averageRotationVelocity.x : averageRotationVelocity.x

            let rotationY = simd_quatf(angle: adjustedDeltaX, axis: SIMD3<Float>(0, 1, 0))
            let cameraRight = cameraNode.simdWorldRight
            let rotationX = simd_quatf(angle: averageRotationVelocity.y, axis: cameraRight)

            let totalRotation = simd_mul(rotationY, rotationX)

            currentRotation = simd_mul(totalRotation, currentRotation)
            ship.shipNode.simdOrientation = currentRotation
        }
    }
    func startContinuousRotation() {
        // Invalidate any existing timer
        longPressTimer.invalidate()

        // Create a new timer that calls applyRotation continuously
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60.0, repeats: true) { _ in
            self.applyRotation()
        }
    }
    func stopContinuousRotation() {
        longPressTimer.invalidate()
    }
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
        // Find the closest black hole and its distance
        var closestDistance: Float = .greatestFiniteMagnitude
        closestBlackHole = nil
        for blackHole in self.blackHoles {
            let distance = simd_distance(blackHole.blackHoleNode.simdWorldPosition, ship.shipNode.simdWorldPosition)
            if distance < closestDistance {
                self.closestBlackHole = blackHole
                closestDistance = distance
            }
        }

        // Check if the ship is in contact with the closest black hole (use a threshold value)
        let contactThreshold: Float = self.closestBlackHole == nil ? 0 : Float(self.closestBlackHole!.radius)
        if closestDistance < contactThreshold {
            points += 100
            self.showScoreIncrement = true
            // Remove black hole from scene and view model
            closestBlackHole?.blackHoleNode.removeFromParentNode()
            if let index = blackHoles.firstIndex(where: { $0 === closestBlackHole }) {
                blackHoles.remove(at: index)
            }

            // Add a new random black hole
            //let newBlackHole = addBlackHole(radius: CGFloat.random(in: 10...50), ringCount: Int.random(in: 1...4), vibeOffset: Int.random(in: 1...2), bothRings: Bool.random(), vibe: "discOh")
            //blackHoles.append(newBlackHole)
            print("Contact with a black hole! Points: \(points)")
        }
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

        // Add the deltaX and deltaY to their respective buffers
        rotationVelocityBufferX.addVelocity(CGFloat(deltaX))
        rotationVelocityBufferY.addVelocity(CGFloat(deltaY))

        // Compute the weighted average velocities
        let weightedAverageVelocityX = rotationVelocityBufferX.weightedAverageVelocity()
        let weightedAverageVelocityY = rotationVelocityBufferY.weightedAverageVelocity()

        // Update the averageRotationVelocity
        averageRotationVelocity = SIMD2<Float>(Float(weightedAverageVelocityX), Float(weightedAverageVelocityY))

        previousTranslation = translation
        isRotationActive = true
        stopContinuousRotation()
    }
    func dragEnded() {
        previousTranslation = CGSize.zero
        isRotationActive = false
        self.rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 5)
        self.rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 5)
        startContinuousRotation()
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
