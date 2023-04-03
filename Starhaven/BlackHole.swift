//
//  BlackHole.swift
//  Starhaven
//
//  Created by JxR on 3/25/23.
//
import Foundation
import SwiftUI
import SceneKit
import Swift
import Metal
import simd

class BlackHole: ObservableObject {
    @Published var blackHoleNode: SCNNode = SCNNode()
    @Published var scene: SCNScene
    @State var radius: CGFloat
    @State var vibeOffset: Int
    @State var ringCount: Int
    @State var bothRings: Bool
    @State var vibe: String
    @State var discMaterial: SCNMaterial = SCNMaterial()
    init(scene: SCNScene, radius: CGFloat, camera: SCNNode, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String) {
        self.scene = scene
        self.radius = radius
        self.ringCount = ringCount
        self.vibeOffset = vibeOffset
        self.bothRings = bothRings
        self.vibe = vibe
        self.addBlackHoleNode(radius: radius)
        //self.addParticleEdgeRings(count: 10, cameraNode: camera)
        self.addSpinningEdgeRings(count: ringCount, cameraNode: camera)
        //self.addMultipleAccretionDisks(count: 10)
        //self.addParticleRingJets(count: 10, cameraNode: camera)
    }
    func addBlackHoleNode(radius: CGFloat) {
        let sphere = SCNSphere(radius: radius)
        let blackHoleMaterial = SCNMaterial()
        blackHoleMaterial.diffuse.contents = UIColor.black
        sphere.materials = [blackHoleMaterial]
        self.blackHoleNode = SCNNode(geometry: sphere)
        //let particleSystem = createGravitationalLensingParticleSystem(radius: self.radius)
        //self.blackHoleNode.addParticleSystem(particleSystem)
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1  * Double.random(in: 1.05...1.15)))
        self.blackHoleNode.runAction(rotationAction)
        let gravityNode = SCNNode()
        let radialGravityField = SCNPhysicsField.radialGravity()
        gravityNode.physicsField = radialGravityField
        radialGravityField.strength = 1000
        self.blackHoleNode.isHidden = false
        self.blackHoleNode.addChildNode(gravityNode)
    }

    func addParticleEdgeRings(count: Int, cameraNode: SCNNode) {
        // ...
    }
    func addSpinningEdgeRings(count: Int, cameraNode: SCNNode, isWhite: Bool = false) {
        let parentNode = self.blackHoleNode
        let mod = self.gravitationalLensingShaderModifiers(currentRing: 1, totalRings: count + count)
        for i in 1..<count {
            let mods = self.gravitationalLensingShaderModifiers(currentRing: i, totalRings: count * self.vibeOffset)
            self.addSpinningEdgeRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mod)
            if Float.random(in: 0...1) < 0.99 { self.addAccretionRing(cameraNode: cameraNode, i: i, mods: mods) }
            self.addLensingRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mods)
            //if Float.random(in: 0...1) < 0.99 { self.addLensedRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mods) }
        }
    }
    func addLensingRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let ringSize: Float = 0.1
        let ringRadius = Float(self.radius + (self.radius/2)) + (Float(i) * (ringSize-0.02))
        let torus = CustomTorus(radius: CGFloat(ringRadius), ringRadius: CGFloat(ringSize), radialSegments: 25, ringSegments: 50)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)

        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)

        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)

        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
    }
    func addSpinningEdgeRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let radius = self.radius
        let torus = CustomTorus(radius: CGFloat(radius), ringRadius: 0.2, radialSegments: 30, ringSegments: 50)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)

        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)

        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)

        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
    }
    func addLensedRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let ringRadius = Float(self.radius) + (Float(i) * Float(self.radius/20))
        let torus = LensedTorus(radius: CGFloat(ringRadius), ringRadius: 0.2, radialSegments: 30, ringSegments: 50)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)

        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)

        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)

        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
    }
    func addAccretionRing(cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let ringRadius = Float(self.radius + (self.radius/2)) + (Float(i) * 0.098)
        let accretionDiskGeometry = SCNTorus(ringRadius: CGFloat(ringRadius), pipeRadius: 0.10 + CGFloat.random(in: -0.001...0.01))
        let accretionDiskMaterial = self.discMaterial
        accretionDiskMaterial.diffuse.contents = UIColor.red
        accretionDiskGeometry.materials = [accretionDiskMaterial]
        let accretionDiskNode = SCNNode(geometry: accretionDiskGeometry)
        accretionDiskGeometry.shaderModifiers = mods
        let x = self.blackHoleNode.position.x
        let z = self.blackHoleNode.position.z
        accretionDiskNode.position = SCNVector3(x, self.blackHoleNode.position.y + Float.random(in: -0.05...0.05), z)
        accretionDiskNode.opacity = CGFloat.random(in: 0.95...1.0)
        self.addRotationToAccretionDisk(accretionDiskNode)
        self.blackHoleNode.addChildNode(accretionDiskNode)
    }
    func addGravitationalLensingEffect(parentNode: SCNNode, cameraNode: SCNNode) {
        let particleSystem = createGravitationalLensingParticleSystem(radius: self.radius)
        let particleNode = SCNNode()
        particleNode.addParticleSystem(particleSystem)
        parentNode.addChildNode(particleNode)
    }

    func createGravitationalLensingParticleSystem(radius: CGFloat) -> SCNParticleSystem {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 1000
        particleSystem.emissionDuration = 10
        //particleSystem.loops = true
        particleSystem.particleLifeSpan = 10
        particleSystem.particleSize = 0.01

        // Configure the particle system's colors and blending mode
        particleSystem.particleColor = UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.90)
        particleSystem.blendMode = .alpha

        // Configure the particle system's emitter shape
        let emitterShape = SCNTorus(ringRadius: self.radius + self.radius, pipeRadius: 1)
        particleSystem.emitterShape = emitterShape

        // Configure the particle system's acceleration and velocity
        particleSystem.acceleration = SCNVector3(0, 0, 0)
        particleSystem.particleVelocity = 1000

        // Configure the particle system's angular velocity
        particleSystem.particleAngularVelocity = 2.0

        return particleSystem
    }
    
    func applyWhiteMaterial(to geometry: SCNGeometry, radius: Float) {
        let edgeRingMaterial = SCNMaterial()
        let randomColorFactor = Float.random(in: 0.1...2.1)
        edgeRingMaterial.diffuse.contents = colorForRadiusFromCenter(radius, randomColorFactor: randomColorFactor)
        geometry.materials = [edgeRingMaterial]
    }

    func setBillboardConstraint(for node: SCNNode) {
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y]
        node.constraints = [billboardConstraint]
    }

    func setRotation(for node: SCNNode, relativeTo blackHoleNode: SCNNode?) {
        guard let blackHoleNode = blackHoleNode else { return }
        let dx = node.position.x - blackHoleNode.position.x
        let dy = node.position.y - blackHoleNode.position.y
        let dz = node.position.z - blackHoleNode.position.z
        let angleX = atan2(dy, sqrt(dx * dx + dz * dz))
        let angleY = atan2(dx, dz)
        node.eulerAngles = SCNVector3(angleX, angleY, 0)
    }

    func rotateAroundBlackHoleCenter(_ node: SCNNode, isWhite: Bool, count: Int) {
        let rotationAxis = SCNVector3(x: 0, y: 0, z: 1)
        let durationMultiplier = 10 * Double.random(in: 0.75...2)
        let rotation = SCNAction.repeatForever(SCNAction.rotate(by: -CGFloat.pi * 1, around: rotationAxis, duration: Double(durationMultiplier)/Double(count)))
        node.runAction(rotation)
    }
    // Add other black hole-related methods here
    func addRotationToAccretionDisk(_ accretionDiskNode: SCNNode) {
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 3, z: 0, duration: 1  * Double.random(in: 1.05...1.15)))
        accretionDiskNode.runAction(rotationAction)
    }
    func gravitationalLensingShaderModifiers(currentRing: Int, totalRings: Int) -> [SCNShaderModifierEntryPoint: String] {
        let randFloat: Float = Float.random(in: 0.0...1)
        let fragmentShaderCode = """
            float3 color = _surface.diffuse.rgb;
            float t = float(\(currentRing)) / float(\(totalRings));
            t = t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;

            float3 red = float3(250.0 / 255.0, 9.0 / 255.0, 5.0 / 255.0);
            float3 orange = float3(220.0 / 255.0, 80.0 / 255.0, 30.0 / 255.0);
            float3 orange2 = float3(250.0 / 255.0, 120.0 / 255.0, 50.0 / 255.0);
            float3 gold = float3(213.0 / 255.0, 65.0 / 255.0, 26.0 / 255.0);
            float3 gold2 = float3(232.0 / 255.0, 89.0 / 255.0, 32.0 / 255.0);
            float3 gold3 = float3(240.0 / 255.0, 95.0 / 255.0, 35.0 / 255.0);
            float3 green = float3(5.0 / 255.0, 9.0 / 255.0, 5.0 / 255.0);
            float3 blue = float3(5.0 / 255.0, 5.0 / 255.0, 250.0 / 255.0);
            float3 purple = float3(120.0 / 255.0, 0.0 / 255.0, 250.0 / 255.0);

            \(self.vibe)
            if (float(\(randFloat)) > 0.95) {
                color = red;
            }
            
            _output.color.rgb = color;

            """

        return [.geometry: String(), .fragment: fragmentShaderCode]
    }
    func colorForRadiusFromCenter(_ radiusFromCenter: Float, randomColorFactor: Float) -> UIColor {
        let whiteFactor = smoothstep(2.45, 2.55, radiusFromCenter) * 2 * randomColorFactor
        let orangeFactor = smoothstep(2.55, 2.65, radiusFromCenter) * randomColorFactor
        let redFactor = smoothstep(2.65, 2.75, radiusFromCenter) * (1.25 * randomColorFactor)
        let darkRedFactor = smoothstep(2.75, 2.85, radiusFromCenter) * (2 * randomColorFactor)
        let blackColor = UIColor(red: 17/255, green: 17/255, blue: 21/255, alpha: 1.0)
        let purpleColor = UIColor(red: 46/255, green: 33/255, blue: 55/255, alpha: 1.0)
        let orangeColor = UIColor(red: 219/255, green: 144/255, blue: 78/255, alpha: 1.0)
        let redColor = UIColor(red: 199/255, green: 74/255, blue: 0/255, alpha: 1.0)
        let darkRedColor = UIColor(red: 119/255, green: 0/255, blue: 0/255, alpha: 1.0)
        let whiteColor = UIColor.white
        let color = blackColor.lerp(to: purpleColor, alpha: CGFloat(darkRedFactor))
            .lerp(to: orangeColor, alpha: CGFloat(redFactor))
            .lerp(to: redColor, alpha: CGFloat(orangeFactor))
            .lerp(to: whiteColor, alpha: CGFloat(whiteFactor))
        return color
    }
    func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }

    func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        return a * (1.0 - t) + b * t
    }
}

struct ShaderVibe {
    static var discOh: String = """
        if (t < 1.0/6.0) {
            color = mix(red, orange, t * 6.0);
        }
        else if (t < 2.0/6.0) {
            color = mix(orange, orange2, (t - 1.0/6.0) * 6.0);
        }
        else if (t < 3.0/6.0) {
            color = mix(orange2, gold3, (t - 2.0/6.0) * 6.0);
        }
        else if (t < 4.0/6.0) {
            color = mix(gold3, red, (t - 3.0/6.0) * 6.0);
        }
        else if (t < 5.0/6.0) {
            color = mix(red, blue, (t - 4.0/6.0) * 6.0);
        }
        else if (t < 5.5/6.0) {
            color = mix(blue, purple, (t - 5.0/6.0) * 6.0);
        }
        else {
            color = mix(purple, red, (t - 5.5/6.0) * 6.0);
        }
    """
    var shaderVibe: String
}
