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
import CoreImage

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
        rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 2)
        rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 2)
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
        self.ship.shipNode = self.ship.createShip()
        scnView.scene?.rootNode.addChildNode(self.cameraNode) // Add this line
        scnView.scene?.rootNode.addChildNode(self.ship.shipNode)
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.black
        scnView.scene?.background.contents = [
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky"),
            UIImage(named: "sky")
        ]
        Task {
            self.ship.createEmitterNode(); self.ship.createWaterParticles(); self.ship.createFireParticles()
            self.ship.shipNode.geometry!.materials = [SCNMaterial()]
            self.ship.shipNode.geometry!.firstMaterial?.diffuse.contents = UIColor.gray
            self.scene.background.intensity = 0.8
            self.blackHoles.append(self.addBlackHole(radius: 100, ringCount: 25, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh, period: 0))
        }
        let blackHole = self.addBlackHole(radius: 100, ringCount: 50, vibeOffset: 2, bothRings: false, vibe: ShaderVibe.discOh, period: 15)
        let redStar = Star(radius: 1000, color: UIColor.red, camera: self.cameraNode)
        redStar.starNode.position = SCNVector3(20000, 0, 0)
        blackHole.blackHoleNode.addChildNode(redStar.starNode)
        let bh = self.addBlackHole(radius: 400, ringCount: 20, vibeOffset: 1, bothRings: false, vibe: ShaderVibe.discOh, period: 15)
        let star = Star(radius: 500, color: UIColor.red, camera: self.cameraNode)
        star.starNode.position = SCNVector3(20_000, 0, 0)
        bh.blackHoleNode.addChildNode(star.starNode)
        // Example usage
        let redStarRadius: Float = 1.0
        let redStarMass: Float = 1.0
        let starValues = convertSolarUnitsToSceneKitUnits(radiusInSolarUnits: redStarRadius, massInSolarUnits: redStarMass)
        let blackHoleRadius: Float = 0
        let blackHoleMass: Float = 8.0
        let blackHoleValues = convertSolarUnitsToSceneKitUnits(radiusInSolarUnits: blackHoleRadius, massInSolarUnits: blackHoleMass)
        print(blackHoleValues.mass, starValues.mass)
        //self.orbit(node1: redStar.starNode, node2: blackHole.blackHoleNode, mass1: starValues.mass, mass2: blackHoleValues.mass)
        for hole in blackHoles {
            scnView.prepare(hole)
        }
        scnView.prepare(blackHole.blackHoleNode)
        scnView.prepare(redStar.starNode)
        scnView.prepare(self.scene)
        return scnView
    }
    // WORLD DYNAMICS
    func orbit(node1: SCNNode, node2: SCNNode, mass1: Float, mass2: Float) {
        // Calculate the center of mass
        let totalMass = mass1 + mass2
        let centerOfMass = SCNVector3(
            x: (node1.position.x * mass1 + node2.position.x * mass2) / totalMass,
            y: (node1.position.y * mass1 + node2.position.y * mass2) / totalMass,
            z: (node1.position.z * mass1 + node2.position.z * mass2) / totalMass
        )
        print(centerOfMass)
        // Calculate the distance between the nodes and the center of mass
        let distance1 = sqrt(pow(node1.position.x - centerOfMass.x, 2) + pow(node1.position.y - centerOfMass.y, 2) + pow(node1.position.z - centerOfMass.z, 2))
        let distance2 = sqrt(pow(node2.position.x - centerOfMass.x, 2) + pow(node2.position.y - centerOfMass.y, 2) + pow(node2.position.z - centerOfMass.z, 2))

        // Calculate the gravitational force between the nodes
        let gravitationalConstant: Float = 6.674e-11
        let force = gravitationalConstant * mass1 * mass2 / pow(distance1 + distance2, 2)

        // Calculate the acceleration of each node
        let acceleration1 = force / mass1
        let acceleration2 = force / mass2

        // Calculate the velocity of each node
        let velocity1 = sqrt(acceleration1 * distance1)
        let velocity2 = sqrt(acceleration2 * distance2)
        // Calculate the direction vector between the nodes
        let direction = node2.position - node1.position
        
        // Calculate the rotation axis using the cross product
        let arbitraryVector = SCNVector3(1, 0, 0)
        let rotationAxis = direction.crossProduct(arbitraryVector).normalized()

        let orbitAction1 = SCNAction.customAction(duration: 100000000) { node, elapsedTime in
            print(velocity1)
            let angle = CGFloat(velocity1) * elapsedTime/1000000
            let diff = node1.position - centerOfMass
            let rotation = SCNMatrix4MakeRotation(Float(angle), rotationAxis.x, rotationAxis.y, rotationAxis.z)
            let newPosition = self.applyAffineTransform(vector: diff, transform: rotation) + centerOfMass
            node1.position = newPosition
        }
        let orbitAction2 = SCNAction.customAction(duration: 100000000) { node, elapsedTime in
            let angle = CGFloat(velocity2) * elapsedTime/1000000
            let diff = node2.position - centerOfMass
            let rotation = SCNMatrix4MakeRotation(Float(angle), rotationAxis.x, rotationAxis.y, rotationAxis.z)
            let newPosition = self.applyAffineTransform(vector: diff, transform: rotation) + centerOfMass
            node2.position = newPosition
        }
        print(velocity1, velocity2)
        // Run the actions on the nodes
        node1.runAction(orbitAction1)
        node2.runAction(orbitAction2)
    }
    // WORLD SCALE
    func applyAffineTransform(vector: SCNVector3, transform: SCNMatrix4) -> SCNVector3 {
        let x = transform.m11 * vector.x + transform.m21 * vector.y + transform.m31 * vector.z + transform.m41
        let y = transform.m12 * vector.x + transform.m22 * vector.y + transform.m32 * vector.z + transform.m42
        let z = transform.m13 * vector.x + transform.m23 * vector.y + transform.m33 * vector.z + transform.m43
        return SCNVector3(x: x, y: y, z: z)
    }
    func convertSolarUnitsToSceneKitUnits(radiusInSolarUnits: Float, massInSolarUnits: Float) -> (radius: Float, mass: Float) {
        let solarValuesInSceneKitUnits = getSolarValuesInSceneKitUnits()
        let solarRadiusInSceneKitUnits = solarValuesInSceneKitUnits.radius
        let solarMassInSceneKitUnits = solarValuesInSceneKitUnits.mass

        let radiusInSceneKitUnits = radiusInSolarUnits * solarRadiusInSceneKitUnits
        let massInSceneKitUnits = massInSolarUnits * solarMassInSceneKitUnits

        return (radiusInSceneKitUnits, massInSceneKitUnits)
    }
    func getSolarValuesInSceneKitUnits() -> (radius: Float, mass: Float) {
        let solarRadiusInMeters: Float = 6.957e8
        let solarMassInKg: Float = 1.988e30

        let distanceConversionFactor: Float = 10_000
        let massConversionFactor: Float = 10000000000

        let solarRadiusInSceneKitUnits = solarRadiusInMeters / distanceConversionFactor
        let solarMassInSceneKitUnits = solarMassInKg / massConversionFactor

        return (solarRadiusInSceneKitUnits, solarMassInSceneKitUnits)
    }
    func convertToRealLifeUnits(sceneKitValue: Float, unitType: String) -> Float {
        let conversionFactor: Float
        if unitType == "distance" {
            conversionFactor = 10_000
        } else if unitType == "mass" {
            conversionFactor = 10_000
        } else {
            return sceneKitValue
        }
        return sceneKitValue * conversionFactor
    }

    func convertToSceneKitUnits(realLifeValue: Float, unitType: String) -> Float {
        let conversionFactor: Float
        if unitType == "distance" {
            conversionFactor = 10_000
        } else if unitType == "mass" {
            conversionFactor = 10_000
        } else {
            return realLifeValue
        }
        return realLifeValue / conversionFactor
    }
    // WORLD SET-UP
    func addBlackHole(radius: CGFloat, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String, period: Float) -> BlackHole {
        let blackHole: BlackHole = BlackHole(scene: self.scene, radius: radius, camera: self.cameraNode, ringCount: ringCount, vibeOffset: vibeOffset, bothRings: bothRings, vibe: vibe, period: period, shipNode: self.ship.shipNode)
        self.scene.rootNode.addChildNode(blackHole.containerNode)
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
        ship.fireParticleSystem.birthRate = CGFloat(50 * value)
        ship.waterParticleSystem.birthRate = CGFloat(50 * value)
        print(ship.throttle)
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
        self.rotationVelocityBufferX = VelocityBuffer(bufferCapacity: 3)
        self.rotationVelocityBufferY = VelocityBuffer(bufferCapacity: 3)
        startContinuousRotation()
    }
    func createLookAtConstraint() -> SCNLookAtConstraint {
        let lookAtConstraint = SCNLookAtConstraint(target: ship.shipNode)
        lookAtConstraint.influenceFactor = 0.5
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
        self.cameraNode.camera?.fieldOfView = 120

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
