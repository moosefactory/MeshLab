//
//  GameCoordinator.swift
//  McIntosh Castle
//
//  Created by Tristan Leblanc on 23/12/2024.
//

import SpriteKit
import Network
import Combine
import MFRemotes
import SceneKit

/// The coordinator makes the junction between app logic, SceneKit view and Overlay
class Coordinator {
    
    /// The SceneKit view controller
    var gridMeshSceneController: SceneController!

    
    var wireframe: Bool = true {
        didSet {
            if wireframe {
                scnView.debugOptions = [.showWireframe, .renderAsWireframe]
            } else {
                scnView.debugOptions = []
            }
        }
    }

    let serviceInfo = MFRemotesServiceInfo(name: "MeshLab Remotes server",
                                        type: "_meshlab._tcp",
                                        version: "1.0")

    public private(set) var remotesAPI: MFRemotesAPIProtocol!
    
    lazy var remotesSession = RemotesSessionManager(serviceInfo: serviceInfo, api: remotesAPI)
        
    public private(set) var scnView: SCNView
    public private(set) var scene: SKScene?
    
    @MainActor public var renderer: SCNSceneRenderer { gridMeshSceneController.sceneRenderer }
    
    /// Lazily return the overlay scene
    lazy var overlayScene: Overlay = Overlay.make(with: self)

    // MARK: - Initialization
    
    /// Init a new coordinator.
    ///
    /// If not remote api is provided, default one is set
    public init(remotesAPI: (any MFRemotesAPIProtocol), scnView: SCNView) {
        self.remotesAPI = remotesAPI
        self.scnView = scnView
    }
    
    
    /// Start our coordinator
    @MainActor func start() {
        presentScene()
        
        remotesSession.startRemotesSession()
        remotesSession.discoverRemotes()
        observeServerState()
        observeRemoteState()
    }

    /// Loads and present the scene
    @MainActor func presentScene() {
        gridMeshSceneController = SceneController(sceneRenderer: scnView)
        gridMeshSceneController.sceneRenderer.overlaySKScene = overlayScene
        changeMode(mode: .camera)
        changeOption(option: .wireframe)
        scnView.allowsCameraControl = true
        overlayScene.isUserInteractionEnabled = false
    }
    
    // MARK: - Events Handling
    
    /// These options are used to treat the hit event
    let hitOptions: [SCNHitTestOption: Any] = [.firstFoundOnly: true, .boundingBoxOnly: false]
    
    var lastLoc: CGPoint?
    
    /// Handle the click or tap event
    /// - Parameter location: The location in the view
    @MainActor func clickOrTap(at location: CGPoint) {
        // If the overlay has handled the event, we quickly return
        guard !overlayScene.handleClickOrTap(at: location) else {
            return
        }
        // Forward to the 3D Scene
        hit(location: location)
    }
    
    /// Handle the double click or tap event
    /// We simply forward to the hit function
    /// - Parameter location: The location in the view
    @MainActor func doubleClickOrTap(at location: CGPoint) {
        // If the overlay has handled the event, we quickly return
        guard !overlayScene.handleClickOrTap(at: location) else {
            return
        }

        hit(location: location)
    }
    
    /// Handle the mouse moved or pan event
    /// We simply forward to the hit function
    /// - Parameter location: The location in the view
    @MainActor func mouseMovedOrPan(at location: CGPoint) {
        // Forward to the 3D Scene
        hit(location: location)
    }
    
    /// Handle mouse or touch events in view
    /// - Parameter location: The location of the event
    @MainActor func hit(location: CGPoint) {
        // Handle event in the 3D scene
        // We find the side index and convert it in grid squares ( 2 triangles per square )
        if let hit = renderer.hitTest(location, options: hitOptions).first {
            gridMeshSceneController.hit(side: hit.faceIndex / 2 )
        }
    }
    
    @MainActor func setScale(_ scale: CGFloat) {
        if let currentScale = gridMeshSceneController.meshPivot?.scale {
            let pinchScale = SCNFloat(scale)
            let nextScale = SCNVector3(x: pinchScale,
                                      y: pinchScale,
                                      z: pinchScale)
            print("scale:\(currentScale)")
            gridMeshSceneController.meshPivot.scale = nextScale
        }
    }
    
    // MARK: - Remotes Session
    
    public var calibrating: Bool {
        get { remotesSession.remote?.calibrating ?? false }
        set { remotesSession.remote?.calibrating = newValue }
    }
    
    public func startStopCalibrating() {
        calibrating = !calibrating
    }
//    
//    public func sendRemoteAction(_ action: Action) {
//        guard let remote = remotesSession.remote else {
//            return
//        }
//        
//        if let data = try? JSONEncoder().encode(action) {
//            remote.send(data)
//        }
//    }
    
    
    /// The remotes session listeners receive changes in the connected devices
    var remoteSessionListeners =  Set<AnyCancellable>()
    
    lazy var gamePadButton: RemoteSessionButton = overlayScene.gamePadButton
    
    /// Start to listen to the remote session
    func observeServerState() {
        overlayScene.gamePadButton.label.text = "Waiting for pair"
        if let server = remotesSession.server {
            
            server.$sessionHostName.sink(receiveValue: { [weak self] value in
                self?.gamePadButton.label.text = value
            }).store(in: &remoteSessionListeners)
            
            server.$running.sink(receiveValue: { [weak self] running in
                let base = self?.remotesSession.server?.sessionHostName ?? ""
                self?.gamePadButton.label.text = "\(base)[Waiting]"
            }).store(in: &remoteSessionListeners)
            
            server.$remoteInterfaces.sink(receiveValue: { [weak self] value in
                if value.count > 0 {
                    print("Got \(value)")
                }
                self?.overlayScene.remotes = value
                let base = self?.remotesSession.server?.sessionHostName ?? ""
                self?.gamePadButton.label.text = "\(base)[\(value.count) Remote]"
            }).store(in: &remoteSessionListeners)
        }
    }

    var discoveredServers: [NWBrowser.Result] = [] {
        didSet {
            print(discoveredServers)
            //overlayScene.waitingForPairing = false
            overlayScene.waitingForPairing = !discoveredServers.isEmpty
        }
    }

    var browserListener: AnyCancellable?
    
    /// Start to listen to the remote connection
    func observeRemoteState() {
        browserListener = remotesSession.$discoveredServers.sink(receiveValue: { results in
            self.discoveredServers = results ?? []
        })
    }

    @MainActor func changeMode(mode: Overlay.Mode) {
        switch mode {
        case .camera:
            scnView.allowsCameraControl = true
            #if os(macOS)
            //scnView.window?.acceptsMouseMovedEvents = false
            #endif
        case .gamePad:
            print("Game")
            remotesSession.startRemote(api: Remote() {[weak self] action in
                guard let discoveredServers = self?.remotesSession.discoveredServers,
                      !discoveredServers.isEmpty else {
                    return
                }
                self?.handle(action: action)
                self?.overlayScene.waitingForPairing = false
                
                let target = SCNVector3(x: 0, y: 0, z: 20)
                let moveCam = SCNAction.move(to: target, duration: 1)
                self?.gridMeshSceneController.cameraNode.runAction(moveCam)}
            )
        case .pencil:
            scnView.allowsCameraControl = false
            // We start tracking mouse moved events on mac
            #if os(macOS)
            //scnView.window?.acceptsMouseMovedEvents = true
            #endif
        }
        
        // We update the overlay back
        overlayScene.mode = mode
    }
    
    func handle(action: Remote.Action) {
        switch action {
        case .start:
            print("start")
        default:
            print("action not handled")

        }
    }
    
    func changeOption(option: Overlay.Option) {
        switch option {
        case .wireframe:
            self.wireframe = !wireframe
        }
        overlayScene.toggleOption(option)
    }
}
