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
    @Published var containerNode: SCNNode = SCNNode()
    @Published var blackHoleNode: SCNNode = SCNNode()
    @Published var scene: SCNScene
    @Published var view: SCNView
    @State var radius: CGFloat
    @State var shipNode: SCNNode
    @State var vibeOffset: Int
    @State var ringCount: Int
    @State var bothRings: Bool
    @State var vibe: String
    @State var period: Float
    @State var discMaterial: SCNMaterial = SCNMaterial()
    init(scene: SCNScene, view: SCNView, radius: CGFloat, camera: SCNNode, ringCount: Int, vibeOffset: Int, bothRings: Bool, vibe: String, period: Float, shipNode: SCNNode) {
        self.scene = scene
        self.view = view
        self.radius = radius
        self.ringCount = ringCount
        self.vibeOffset = vibeOffset
        self.bothRings = bothRings
        self.shipNode = shipNode
        self.vibe = vibe
        self.period = period
        self.addBlackHoleNode(radius: radius)
        //self.addParticleEdgeRings(count: 10, cameraNode: camera)
        self.addSpinningEdgeRings(count: ringCount, cameraNode: camera)
        //self.addMultipleAccretionDisks(count: 10)
        //self.addParticleRingJets(count: 10, cameraNode: camera)
        self.containerNode.addChildNode(blackHoleNode)
    }
    func addBlackHoleNode(radius: CGFloat) {
        let sphere = SCNSphere(radius: radius)
        let blackHoleMaterial = SCNMaterial()
        blackHoleMaterial.diffuse.contents = UIColor.black
        sphere.materials = [blackHoleMaterial]
        self.blackHoleNode = SCNNode(geometry: sphere)
        //let particleSystem = createGravitationalLensingParticleSystem(radius: self.radius)
        //self.blackHoleNode.addParticleSystem(particleSystem)
        let rotationAction = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: self.period == 0 ? 2  * Double.random(in: 0.5...1.15) : Double(self.period)))
        self.blackHoleNode.runAction(rotationAction)
        self.blackHoleNode.isHidden = false
        let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur")
        let pixellateFilter = CIFilter(name:"CIPixellate")
        self.view.prepare(blackHoleNode)
    }
    func addSpinningEdgeRings(count: Int, cameraNode: SCNNode, isWhite: Bool = false) {
        let parentNode = self.blackHoleNode
        let mod = self.gravitationalLensingShaderModifiers(currentRing: 1, totalRings: 1)
        
        // Create a single material
        let material = SCNMaterial()
        material.emission.contents = UIColor.red
        //aterial
        for i in 1..<count {
            let mods = self.gravitationalLensingShaderModifiers(currentRing: i, totalRings: count * self.vibeOffset)
            self.addSpinningEdgeRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mod)
            
            // Pass the material to the addAccretionRing function
            if Float.random(in: 0...1) < 0.95 { self.addAccretionRing(cameraNode: cameraNode, i: i, mods: mods, material: material) }
            
            if Float.random(in: 0...1) < 0.95 { self.addLensingRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mods) }
            
            //if Float.random(in: 0...1) < 0.95 { self.addLensedRing(parentNode: parentNode, cameraNode: cameraNode, i: i, mods: mods) }
        }
        self.addLensingRing(parentNode: parentNode, cameraNode: cameraNode, i: count, mods: mod)
        self.addLensingRing(parentNode: parentNode, cameraNode: cameraNode, i: count, mods: mod)
        self.addAccretionRing(cameraNode: cameraNode, i: count, mods: mod, material: material)
    }
    func addAccretionRing(cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String], material: SCNMaterial) {
        let scaleConstant: Float = Float(self.radius * 0.1)
        let scaleFactor: Float = scaleConstant * Float(i)
        let ringRadius = Float(self.radius) + Float(self.radius/1) + scaleFactor
        let accretionDiskGeometry = SCNTorus(ringRadius: CGFloat(ringRadius), pipeRadius: CGFloat(scaleConstant))
        accretionDiskGeometry.materials = [material]
        let accretionDiskNode = SCNNode(geometry: accretionDiskGeometry)
        accretionDiskGeometry.shaderModifiers = mods
        let x = self.blackHoleNode.position.x
        let z = self.blackHoleNode.position.z
        accretionDiskNode.position = SCNVector3(x, self.blackHoleNode.position.y, z)
        accretionDiskNode.opacity = CGFloat.random(in: 0.85...1.0)
        self.view.prepare(accretionDiskNode)
        self.addRotationToAccretionDisk(accretionDiskNode)
        self.blackHoleNode.addChildNode(accretionDiskNode)
    }
    func addLensingRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let scaleConstant: Float = Float(self.radius * 0.1)
            let scaleFactor: Float = scaleConstant * Float(i)
        let ringRadius = Float(self.radius) + Float(self.radius) + scaleFactor
            let pipeRadius = CGFloat(scaleConstant)
            let torus = CustomTorus(radius: CGFloat(ringRadius), ringRadius: pipeRadius, radialSegments: 25, ringSegments: 50)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)
        edgeRingNode.opacity = CGFloat.random(in: 0.85...1.0)
        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)
        self.view.prepare(edgeRingNode)
        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)

        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
    }
    func addSpinningEdgeRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let radius = self.radius
        let torus = CustomTorus(radius: CGFloat(radius) + 1 + CGFloat(Double(i) * 1.5), ringRadius: 0.10 * radius, radialSegments: 30, ringSegments: 30)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)

        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)
        self.view.prepare(edgeRingNode)
        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)

        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
    }
    func addLensedRing(parentNode: SCNNode, cameraNode: SCNNode, isWhite: Bool = false, i: Int, mods: [SCNShaderModifierEntryPoint: String]) {
        let scaleConstant: Float = Float(self.radius * 0.1)
        let scaleFactor: Float = scaleConstant * Float(i)
        let ringRadius = Float(self.radius) + Float(self.radius/1.5) + scaleFactor
        let pipeRadius = CGFloat(scaleConstant) + CGFloat.random(in: -0.001...0.01)
        let torus = LensedTorus(radius: CGFloat(ringRadius), ringRadius: pipeRadius, radialSegments: 30, ringSegments: 30)
        torus.geometry!.shaderModifiers = mods
        let edgeRingNode = SCNNode(geometry: torus.geometry)

        // Create a new parent node for the edge ring and apply the billboard constraint to it
        let edgeRingParentNode = SCNNode()
        setBillboardConstraint(for: edgeRingParentNode)
        parentNode.addChildNode(edgeRingParentNode)

        // Add the edge ring node as a child of the parent node
        edgeRingParentNode.addChildNode(edgeRingNode)
        edgeRingNode.opacity = CGFloat.random(in: 0.85...1.0)
        setRotation(for: edgeRingNode, relativeTo: blackHoleNode)

        rotateAroundBlackHoleCenter(edgeRingNode, isWhite: isWhite, count: i)
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
            color = mix(red, purple, (t - 4.0/6.0) * 6.0);
        }
        else if (t < 5.5/6.0) {
            color = mix(purple, blue, (t - 5.0/6.0) * 6.0);
        }
        else if (t < 5.95/6.0) {
            color = mix(blue, red, (t - 5.5/6.0) * 6.0);
        }
        else {
            color = red;
        }
    """
    var shaderVibe: String
}
