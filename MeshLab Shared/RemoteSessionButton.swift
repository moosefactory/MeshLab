//
//  LayeredButton.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 12/01/2025.
//

import SpriteKit

class RemoteSessionButton: SKSpriteNode {
    
    var numberOfRemotes: Int = 0
    
    func reset() {
        remoteSateliteIconOverlay.removeFromParent()
        remoteIcons.forEach { $0.removeFromParent() }
        numberOfRemotes = 0
    }
    
    func addRemote(){
        let remoteIcon = remoteSateliteIconOverlay.copy() as! SKSpriteNode
        remoteIcons.append(remoteIcon)
        addChild(remoteIcon)
    }
    
    func removeRemote(){
        if let last = remoteIcons.last {
            last.removeAllActions()
            last.removeFromParent()
            remoteIcons.dropLast()
        }
    }

    var remoteIcons: [SKSpriteNode] = []
    
    lazy var radarIconOverlay: SKSpriteNode = childNode(withName: "ScanOverlay") as! SKSpriteNode
    lazy var icon: SKSpriteNode = childNode(withName: "Icon") as! SKSpriteNode
    lazy var remoteSateliteIconOverlay: SKSpriteNode = childNode(withName: "RemoteOverlay") as! SKSpriteNode
    
    lazy var label: SKLabelNode = childNode(withName: "hostNameLabel") as! SKLabelNode

    /// Note that this is not called on creation, but when the sprite is programatically moved to another sprite.
    override func move(toParent parent: SKNode) {
        remoteSateliteIconOverlay.removeFromParent()
    }
    
    var scanning: Bool = false { didSet {
        radarIconOverlay.isHidden = !scanning
        if scanning {
            let action = SKAction.rotate(byAngle: .pi, duration: 2)
            radarIconOverlay.run(SKAction.repeatForever(action))
        } else {
            radarIconOverlay.removeAllActions()
            radarIconOverlay.isHidden = true
        }
    }}
}
