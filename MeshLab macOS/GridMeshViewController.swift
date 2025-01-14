//
//  GridMeshViewController.swift
//  MeshLab macOS
//
//  Created by Tristan Leblanc on 05/01/2025.
//

import Combine

import Cocoa
import SceneKit
import SpriteKit

import MFRemotes


/// The macOS view controller
///
/// To keep cross platform smooth, the view controller simply creates a coordinator to host all the logic.
///
/// We mainly need to class to catch user interactions events

class GridMeshViewController: NSViewController {
    
    /// The coordinator does the link between the app logic, the SceneKit 3D scene, and the SpriteKit overlay
    
    lazy var coordinator = Coordinator(remotesAPI: Remote(),
                                              scnView: scnView)

    /// Convenient accessor to SceneKit SCNView
    var scnView: SCNView { self.view as! SCNView }
    
    
    /// We keep app gestures in an array for enable/disable
    var appGestureRecognizers = Set<NSGestureRecognizer>()

    /// Configure gestures
    override func viewDidLoad() {
        super.viewDidLoad()

        coordinator.start()
        
        configureGestures()
    }

    /// Configures the view gesture recognizers
    /// Gesture recognizers are stored in the 'appGestureRecognizers' set
    func configureGestures() {
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        
        let doubleClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        doubleClickGesture.numberOfClicksRequired = 2
        
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        appGestureRecognizers = [
            clickGesture, doubleClickGesture, panGesture
        ]
        
        appGestureRecognizers.forEach { view.gestureRecognizers.insert($0, at: 0) }
    }
    
    /// Handle the click gesture by passing the location to the coordinator
    /// - Parameter gestureRecognizer: The source gesture recognizer
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        coordinator.clickOrTap(at: gestureRecognizer.location(in: nil))
    }
    
    @objc
    func handlePan(_ gestureRecognizer: NSPanGestureRecognizer) {
        coordinator.mouseMovedOrPan(at: gestureRecognizer.location(in: nil))
    }
    /// Propagates the mouse moved events through the coordinator
    /// - Parameter event: The mouse event
//    override func mouseMoved(with event: NSEvent) {
//        coordinator.mouseMovedOrPan(at: event.locationInWindow)
//    }
    
    @objc
    func handleDoubleClick(_ gestureRecognizer: NSGestureRecognizer) {
        coordinator.clickOrTap(at: gestureRecognizer.location(in: nil))
    }

}
