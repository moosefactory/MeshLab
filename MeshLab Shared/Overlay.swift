//
//  RemotesScene.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 10/01/2025.
//

import SpriteKit
import MFRemotes

protocol ButtonOption: RawRepresentable { }

extension ButtonOption {
    var buttonName: String { "\(self.rawValue)Button" }
    var buttonFileName: String { "\(self.rawValue)" }
}

class Overlay: SKScene {
    
    enum Status {
        case waitingForPairs
        case waitingForPairing
    }
    
    /// Some constants used in the layout of the overlay
    struct Metrics {
        static let margin = 60.0
        static let topMargin = 90.0
    }
    
    /// The type for mode buttons.
    ///
    /// Mode is a sticky value, contrarily to Option.
    /// It is used to keep track of the current selected tool.
    /// - camera control
    /// - game pad
    /// - pencil
    enum Mode: String, CaseIterable, ButtonOption {
        case camera = "Camera"
        case gamePad = "GamePad"
        case pencil = "Pencil"
    }
    
    /// The type for option buttons.
    ///
    /// Options trigger instant actions, like 'toggle wireframe' or 'randomize'
    enum Option: String, CaseIterable, ButtonOption {
        case wireframe = "Wireframe"
    }
    
    /// The type for option buttons.
    ///
    /// Options trigger instant actions, like 'toggle wireframe' or 'randomize'
    enum Action: String, CaseIterable, ButtonOption {
        case randomize = "Randomize"
    }

    // MARK: - Properties
    
    /// The scene coordinator.
    var coordinator: Coordinator?
    
    /// The current mode
    var mode: Mode = .camera { didSet {
        updateModeButtons()
    }}
    
    /// The list of connected remotes
    var remotes: [RemoteInterface] = [] { didSet {
        waitingForPairing = remotes.isEmpty
        let dif = remotes.count - oldValue.count
        if dif < 0 {
            for _ in 0 ..< -dif { gamePadButton.removeRemote() }
        } else if dif > 0 {
            for _ in 0 ..< dif { gamePadButton.addRemote() }
        }
    }}
    
    // MARK: - Sprite Access
    
    lazy var modeButtonsPanel: SKNode = childNode(withName: "/modeButtons")!
    
    lazy var optionButtonsPanel: SKNode = childNode(withName: "/optionButtons")!
    
    lazy var gamePadButton: RemoteSessionButton = childNode(withName: "/modeButtons/GamePadButton") as! RemoteSessionButton
    
    lazy var randomizeButton: SKNode = childNode(withName: "/optionButtons/RandomizeButton")!

    lazy var buttons: [SKSpriteNode] = Mode.allCases.map {
        modeButtonsPanel.childNode(withName: $0.buttonName) as! SKSpriteNode
    }
    
    lazy var optionButtons: [SKSpriteNode] = Option.allCases.map {
        optionButtonsPanel.childNode(withName: $0.buttonName) as! SKSpriteNode
    }
    
    // MARK: - Initialization
    
    /// Creates a new overlay
    ///
    /// We use a static function to avoid messing around with initializers ( Init with filename can't be called by subclass )
    /// - Parameter coordinator: The coordinator that creates the overlay
    /// - Returns: The overlay SKScene
    static func make(with coordinator: Coordinator) -> Overlay {
        let scene = SKScene(fileNamed: "Overlay") as! Overlay
        scene.coordinator = coordinator
        
        scene.waitingForPairing = true
        scene.isPaused = false
        scene.gamePadButton.reset()
        return scene
    }
    
    /// THIS FUNCTION IS NEVER CALLED WHEN USED AS OVERLAY - Owner SKView is nil in this case
    /// Don't loose your time to implement it
    override func didMove(to view: SKView) { }
    
    /// We update buttons positions when the scene is resized
    /// - Parameter oldSize: the previous size
    override func didChangeSize(_ oldSize: CGSize) {
        modeButtonsPanel.position = CGPoint(x: Metrics.margin,
                                            y: size.height - Metrics.topMargin)
        optionButtonsPanel.position = CGPoint(x: size.width - Metrics.margin,
                                              y: size.height - Metrics.topMargin)
    }
    
    func toggleOption(_ option :Option) {
        
        if let index = options.firstIndex(where: { anOption in
            anOption == option
        }) {
            options.remove(at: index)
        } else {
            options.append(option)
        }
        updateOptionButtons()
    }
    
    var options: [Option] = []
    
    var waitingForPairing: Bool = true { didSet {
        gamePadButton.scanning = waitingForPairing
        updateModeButtons()
    }}

    func updateModeButtons() {
        buttons.forEach { node in
            guard let modeStr = node.userData?["action"] as? String,
                  let buttonMode = Mode(rawValue: modeStr) else { return }
            let isButtonEnabled = isButtonEnabled(action: modeStr)
            let term = buttonMode == mode ? "_On" : ""
            let tex = SKTexture(imageNamed: "\(buttonMode.buttonFileName)\(term)")
            if let gamepadButton = node as? RemoteSessionButton {
                gamepadButton.icon.texture = tex
            } else {
                node.texture = tex
            }
            node.alpha = isButtonEnabled ? 1 : 0.35
            node.isUserInteractionEnabled = isButtonEnabled
        }
    }
    
    func isButtonEnabled(action: String) -> Bool {
        if action == Mode.gamePad.rawValue {
            return waitingForPairing
        }
        return true
    }
    
    func updateOptionButtons() {
        optionButtons.forEach { node in
            
            guard let optionStr = node.userData?["action"] as? String,
                  let buttonOption = Option(rawValue: optionStr)
            else { return }
            

            let term = self.options.contains(buttonOption) ? "_On" : ""
            let tex = SKTexture(imageNamed: "\(buttonOption.buttonFileName)\(term)")
            
            node.texture = tex
        }
    }
    
    /// Handle the click or tap from the coordinator
    /// - Parameter location: The location in the view
    /// - Returns: true if a button is hit
    func handleClickOrTap(at location: CGPoint) -> Bool {
        guard let coordinator = coordinator else { return false }
        
        var location = location // Local mutable copy
        
        //  Y axis is reversed on iOS
        #if os(iOS)
        let hLoc = (location.x / size.width) * size.width
        let vLoc = (location.y / size.height) * size.height
        location = CGPoint(x: hLoc, y:size.height - vLoc)
        #endif
        
        let overlayTapedItem = atPoint(location)

        guard let data = overlayTapedItem.userData?["action"] as? String else {
            return false
        }
        
        if let mode = Overlay.Mode(rawValue: data) {
            coordinator.changeMode(mode: mode)
            return true
        }
        else if let option = Overlay.Option(rawValue: data) {
            coordinator.changeOption(option: option)
            return true
        }
        
        let action = Remote.Action(identifier: data)
        coordinator.handle(action: action)
        
        return true
    }
    
}
