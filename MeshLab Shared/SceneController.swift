//
//  GridMeshSceneController.swift
//  MeshLab Shared
//
//  Created by Tristan Leblanc on 05/01/2025.
//

import Combine

import SceneKit
import SpriteKit

import MFFoundation
import MFSCNExtensions
import MFGridUtils
import MFRemotes

class CellData: Equatable {
    
    internal init(value: Double = .random()) {
        self.value = value
    }
    
    var value: Double = .random()
    
    static func == (lhs: CellData, rhs: CellData) -> Bool {
        lhs.value == rhs.value
    }
}

/// GridMeshSceneController displays a mesh in a scene kit view using MFSCNExtensions.
///
/// The height function of the mesh can be either a random wave function or depth data from the camera on devices supporting Lidar.

@MainActor
class SceneController: NSObject, SCNSceneRendererDelegate {
    
    /// The mesh resolution
    let resolution = 32
    
    var phase: CGFloat = 0.0
    var attenuation: CGFloat = 1.0
    
    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer
    
    /// The meshBuilder keeps all info necessary to mesh creation, and generates geometry on demand.
    var meshBuilder: MFSCNGridMesh
    
    /// The mesh information used to configure the mesh builder
    var meshInfo: MFSCNMeshInfo
    
    /// The mesh node itself, set to the result of the mesh builder
    var meshNode: SCNNode? = nil
    var cameraNode: SCNNode { scene.rootNode.childNode(withName: "camera", recursively: true)! }
    var meshPivot: SCNNode!
    
    var gridBitmap: CGContext!
    
    lazy var functionParams = FunctionParams()
    
    var grid: MFGrid!
    
    var dataLayer: MFGridDataLayer<CellData>!
    
    var lastLoc: CGPoint?
    
    var scale: CGFloat = 1 {
        didSet {
            var h = meshBuilder.meshInfo.heightMapInfo?.height ?? 0
            h *= scale
            meshBuilder.meshInfo.heightMapInfo?.height = h
            meshNode?.geometry = try? meshBuilder.makeGeometry()
        }
    }
    
    var servers: [MFRemotesSessionServerBrowserResult]? {
        didSet {
            print("connected to remote session")
        }
    }
    
#if !os(macOS) && !os(tvOS)
    
    /// On iOS, this property is set on capure data reception.
    /// Mesh heights are then updated accordingly
    var lidarData: CameraCapturedData? {
        didSet {
            lidarDataDidUpdate()
        }
    }
    
#endif
    
    // MARK: - Initialise
    
    init(sceneRenderer renderer: SCNSceneRenderer) {
        
        sceneRenderer = renderer
        
        scene = SCNScene(named: "Art.scnassets/stage.scn")!
        
        // 1 Grid Init
        
        let gridInfo = MFSCNTerrainMesh.GridInfo(gridSize: try! MFGridSize.init(size: UInt(resolution)),
                                                 cellSize: CGSize.square(0.07 * 128.0 / CGFloat(resolution)))
        
        // 2 Height data and closure
        
        let heightInfo = MFSCNMeshHeightMapInfo(with: nil,
                                                height: 2,
                                                textureScale: CGSize.one)
        
        // 3 Texture
        
        let textureInfo = MFSCNMeshTextureInfo(textureScale: .one,
                                               textureBaseName: "Icon_512",
                                               color: PlatformColor.blue)
        // Assemble mesh information
        
        
        meshInfo = MFSCNMeshInfo(gridInfo: gridInfo,
                                 heightMapInfo: heightInfo,
                                 mappingInfo: textureInfo)
        
        meshBuilder = try! MFSCNGridMesh(meshInfo: meshInfo)
        
        let meshPivot: SCNNode = scene.rootNode.childNode(withName: "meshPivot", recursively: true)!
        let geometry = try! meshBuilder.makeGeometry()
        let material = meshBuilder.makeMaterial()
        geometry.firstMaterial = material
        let meshNode = SCNNode(geometry: geometry)
        meshPivot.addChildNode(meshNode)
        
        super.init()
        
        self.meshPivot = meshPivot
        self.meshNode = meshNode
        
        meshNode.castsShadow = true
        
        sceneRenderer.delegate = self
        
        sceneRenderer.scene = scene
        
        sceneRenderer.pointOfView = cameraNode
        updatePosition()
        startAnimation()
    }
    
    func startAnimation() {
        let _ = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [self] timer in
            DispatchQueue.main.async {
                self.idle()
            }
        }
    }
    
    var phaseSpeed: CGFloat = 0.01
    
    func randomize() {
        functionParams = FunctionParams.random()
        attenuation = 1.0
        phaseSpeed = 0.01
    }
    
    @MainActor func idle() {
        computeSurface()
        
        let geometry = try! meshBuilder.makeGeometry()
        let material = meshBuilder.makeMaterial()
        geometry.firstMaterial = material
        meshNode!.geometry = geometry
        meshNode!.castsShadow = true
        phase += phaseSpeed
        phaseSpeed *= functionParams.speedAttenuationFactor
        attenuation *= functionParams.attenuationFactor
        if attenuation < 0.0002 {
            attenuation = 1.0
            phaseSpeed = 0.1
            functionParams = FunctionParams.random()
        }
        updatePosition()
        
        if let lastLoc = lastLoc {
            hit(location: lastLoc)
        }
    }
    
    func updatePosition() {
        guard let meshNode = meshNode else { return }
        let meshCenter = meshNode.boundingSphere.center
        meshNode.position = SCNVector3(x: -meshCenter.x, y: -meshCenter.y, z: 0.0)
        
        meshPivot.worldPosition = SCNVector3(x: 0, y: 0, z: 0)
        meshPivot.rotation = SCNVector4(x: -1, y: 0.0, z: 0, w: .pi / 2)
    }
    
    /// Initialize the grid object
    func makeGrid() {
        let gridSize = try! MFGridSize(size: UInt(resolution))
        let cellSize = CGSize.square(20)
        
        let grid = MFDataGrid(gridSize:gridSize,
                              cellSize: cellSize)
        self.grid = grid
        
        let dataLayer = makeDataLayer(with: grid)
        self.dataLayer = dataLayer.dataLayer as? MFGridDataLayer<CellData>
        
    }
    
    func computeSurface() {
        if grid == nil {
            makeGrid()
        }
        let f = self.functionParams
        let height = f.maxHeight * attenuation
        
        let heightComputeBlock: MFSCNHeightComputeBlock = {
            value, gridLoc, fractionalLoc  in
            
            let dx = fractionalLoc.x - 0.5
            let dy = fractionalLoc.y - 0.5
            
            let distanceToCenter: CGFloat = f.distanceToCenterStart + sqrt(dx * dx + dy * dy)
            // lower the amplitude as we escape from the center
            let  damping = CGFloat(powf(Float(f.exponentStart + distanceToCenter * f.dampingScale), Float(f.exponent)))
            
            let angle: CGFloat = (self.phase + distanceToCenter) * f.scale
            let sinus = CGFloat( sinf(Float(angle)))
            return  sinus * height / damping
        }
        
        
//        if gridBitmap == nil {
//            let bitmap = try? grid.makeContext(gridStyle: gridStyle)
//            self.gridBitmap = bitmap
//        } else {
//            grid.render(context: gridBitmap, style: gridStyle)
//        }
//        
//        
//        if let bitmap = self.gridBitmap {
//            self.meshBuilder.meshInfo.mappingInfo = MFSCNMeshTextureInfo(textureScale: .one,
//                                                                         textureBitmap: bitmap,
//                                                                         color: nil)
//        }
//        
        self.meshBuilder.meshInfo.heightMapInfo = MFSCNMeshHeightMapInfo(with: nil,
                                                                         height: 5,
                                                                         textureScale: CGSize.one,
                                                                         heightComputeBlock: heightComputeBlock)
        
    }
    
    let gridStyle = MFGridStyle(strokeColor: .white, fillColor: .white.withAlphaComponent(0.3), strokeWidth: 0.5)
    
    let birthProbability = 0.02
    
    func makeDataLayer(with grid: MFDataGrid) -> MFGridDataLayerItem {
        let layer = MFGridDataLayer<CellData>.init(grid: grid,
                                                   allocator: { scanner in
            let g = scanner.cell.gridLocation
            let bl = g.v == 0 && g.h == 0
            let br = g.v == 0 && g.h == grid.gridSize.columns - 1
            let tr = g.v == grid.gridSize.rows - 1 && g.h == 0
            
            let f = scanner.cell.fractionalFrame.origin
            return (bl || tr || br) ? CellData(value: f.x * f.y) : nil
        },
                                                   cellRenderer: {
            scanner, context, data in
            
            let frame = scanner.cell.fractionalFrame
            
            context.saveGState()
            context.addRect(frame)
            let f = frame.origin
            let g = scanner.cell.gridLocation
            let bl = g.v == 0 && g.h == 0
            let br = g.v == 0 && g.h == grid.gridSize.columns - 1
            let tr = g.v == grid.gridSize.rows - 1 && g.h == 0
            context.setFillColor(red: bl ? 1 : 0.5 + f.y / 2,
                                 green: tr ? 1 : 0.5 + f.x / 2,
                                 blue: br ? 1 : data.value,
                                 alpha:(bl || tr || tr) ? 1 : 0.9 + Double.random(0.1))
            context.fillPath()
            context.restoreGState()
        })
        
        let item = MFGridDataLayerItem(dataLayer: layer, type: CellData.self)
        grid.dataLayers.append(item)
        return item
    }
    
    func hit(side: Int) {
        if let gridLocation = grid.location(at: side) {
            self.dataLayer.write(data: CellData(), at: gridLocation)
        }
    }
    
    func hit(location: CGPoint) {
        let location = CGPoint(x: location.x, y: location.y)
        
        let r = sceneRenderer.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true, .boundingBoxOnly: false])
        if let hit = r.first {
            self.hit(side: hit.faceIndex / 2 )
        }
    }
    
    func highlight(at location: CGPoint) {
        
    }
    
    nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered on the SCNSceneRenderer thread
        
    }
}
