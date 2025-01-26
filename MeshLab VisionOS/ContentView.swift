//
//  ContentView.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 26/01/2025.
//

import SwiftUI
import RealityKit
import SceneKit
import MFSCNExtensions
//import RealityKitContent


let scene = SCNScene(named: "Art.scnassets/stage.scn")!

func makeCoordinator(scnView: SCNView) {
    scnView.allowsCameraControl = true
    scnView.scene = scene
    let coord = Coordinator(remotesAPI: Remote(), scnView: scnView)
    DispatchQueue.main.async {
        coord.presentScene()
    }
}

struct SwiftUISceneView : UIViewRepresentable {
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    

    func makeUIView(context: Context) -> UIView {
        let scnView = SCNView()
        MeshLab_visionOS.makeCoordinator(scnView: scnView)
        return scnView
    }

}

struct ContentView: View {

    var body: some View {
        VStack {
            SwiftUISceneView()
            
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
