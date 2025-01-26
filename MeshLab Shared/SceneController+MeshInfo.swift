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
import MFSCNExtensions

extension SceneController {
    
    func makeMeshInfo() -> MFSCNMeshInfo {
        
        // 1 Grid Init
        
        let gridInfo = MFSCNMeshGridInfo(gridSize: try! MFGridSize.init(size: UInt(resolution)),
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
        
        
        return MFSCNMeshInfo(gridInfo: gridInfo,
                            heightMapInfo: heightInfo,
                            mappingInfo: textureInfo)
    }
}
