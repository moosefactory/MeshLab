//
//  GridMeshViewController.swift
//  MeshLab tvOS
//
//  Created by Tristan Leblanc on 05/01/2025.
//

import UIKit
import SceneKit

class GridMeshViewController: UIViewController {
    #if os(iOS)
    var isLidarAvailable: Bool = true
    #endif
    
    
    /// The coordinator does the link between the app logic, the SceneKit 3D scene, and the SpriteKit overlay
    
    lazy var coordinator = Coordinator(remotesAPI: Remote(),
                                              scnView: scnView)

    /// Convenient accessor to SceneKit SCNView
    var scnView: SCNView { self.view as! SCNView }
    
    
    /// We keep app gestures in an array for enable/disable
    var appGestureRecognizers = Set<UIGestureRecognizer>()

    var panGesture: UIPanGestureRecognizer!

#if !os(macOS) && !os(tvOS)

    ///
    internal var listeners = Set<AnyCancellable>()
    
    var lidarCameraManager: CameraManager?
    
    var lidarData: CameraCapturedData? {
        didSet {
           // gridMeshSceneController.lidarData = lidarData
        }
    }
    #else
    func startLidar() {
        print("Can't use Lidar on this platform")
    }
#endif

    override func viewDidLoad() {
        super.viewDidLoad()
        startLidar()
        coordinator.start()
        configureGestures()
    }
    
    func configureGestures() {
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        tapGesture.numberOfTapsRequired = 1
        // Add a pan gesture recognizer, to detect drag (to draw in pencil mode)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

        let appGestureRecognizers = [
            panGesture
        ]
        
        view.gestureRecognizers?.append(tapGesture)

        appGestureRecognizers.forEach {
            self.appGestureRecognizers.insert($0)
            view.gestureRecognizers?.append($0)
        }
    }
            
    @objc
    func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        coordinator.clickOrTap(at: gestureRecognizer.location(in: nil))
        let gesturesEnabled = coordinator.overlayScene.mode != .camera
        appGestureRecognizers.forEach { $0.isEnabled = gesturesEnabled }
    }

    @objc
    func handlePan(_ gestureRecognizer: UISwipeGestureRecognizer) {
        let loc = gestureRecognizer.location(in: nil)
        coordinator.hit(location: loc)
    }
    
}
