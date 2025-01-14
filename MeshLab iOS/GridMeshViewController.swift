//   /\/\__/\/\      MFFoundation
//   \/\/..\/\/      Swift Framework - v2.0
//      (oo)
//  MooseFactory     ©2007-2025 - Moose
//    Software
//  ------------------------------------------
//  GridMeshViewController.swift
//  MeshLab iOS
//
//  Created by Tristan Leblanc on 05/01/2025.

import UIKit
import Combine

import MFSCNExtensions

import SceneKit
import SpriteKit

import MFFoundation
import MFRemotes


/// The iOS view controller
///
/// To keep cross platform smooth, the view controller simply creates a coordinator to host all the logic.
///
/// We mainly need to class to catch user interactions events

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
        // Add a pinch gesture to let the user zoom when camera control is disabled ( pencil mode )
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))

        let appGestureRecognizers = [
            panGesture, pinchGesture
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
    
    @objc
    func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        coordinator.setScale(gestureRecognizer.scale)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        Device.isPhone ? .allButUpsideDown : .all
    }
    
    override var prefersStatusBarHidden: Bool { true }

}
