//
//  SceneController+MeshInfo.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 16/01/2025.
//

import Foundation
import MFSCNExtensions
import UniColor
import MFGridUtils

extension SceneController {
    
    func makeMeshInfo() -> MFSKMeshInfo {
        
        // 1 Grid Init
        
        let gridInfo = MFSCNTerrainMesh.GridInfo(gridSize: try! MFGridSize.init(size: UInt(resolution)),
                                                 cellSize: CGSize.square(0.07 * 128.0 / CGFloat(resolution)))
        
        // 2 Height data and closure
        
        let heightInfo = MFSKMeshHeightMapInfo(with: nil,
                                               height: 2,
                                               textureScale: CGSize.one)
        
        // 3 Texture
        
        let textureInfo = MFSKMeshTextureInfo(textureScale: .one,
                                              textureBaseName: "Icon_512",
                                              color: PlatformColor.blue)
        // Assemble mesh information
        
        
        return MFSKMeshInfo(gridInfo: gridInfo,
                            heightMapInfo: heightInfo,
                            mappingInfo: textureInfo)
    }
}
