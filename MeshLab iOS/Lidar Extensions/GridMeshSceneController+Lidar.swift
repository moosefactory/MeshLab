//
//  Lidar.swift
//  TerrainMesh
//
//  Created by Tristan Leblanc on 05/01/2025.
//
import SceneKit
import MFFoundation
import MFGridUtils
import MFSCNExtensions
import CoreGraphics

extension SceneController {
    
#if !os(macOS) && !os(tvOS) && !os(watchOS)
    
    // MARK: - Camera Data Updated
    
    func lidarDataDidUpdate() {
        
        // Access depth layer texture
        guard let depthTexture = lidarData?.depth,
              let colors = lidarData?.colorY else {
            return
        }
        
        // Create a CIImage from the texture ioSurface
        let ciImage = CIImage(ioSurface: depthTexture.iosurface!,
                              options: [CIImageOption.auxiliaryDepth: true])
        
        do {
            if let cgImage = ciImage.toCGImage() {
                let uiImage =  UIImage(cgImage: cgImage)
                let bitmap = try uiImage.bitmap()
                
                self.meshBuilder.meshInfo.heightMapInfo =
                MFSCNMeshHeightMapInfo(with: bitmap, height: 5)
            }
            
            if let cgImage = ciImage.toCGImage() {
                let uiImage =  UIImage(cgImage: cgImage)
                let bitmap = try uiImage.bitmap()
                
                self.meshBuilder.meshInfo.mappingInfo = MFSCNMeshTextureInfo(textureScale: .one, textureBitmap: bitmap, color: nil)
            }
            
            self.meshNode?.geometry = try! self.meshBuilder.makeGeometry()

        } catch {
            print("ERROR")
        }
    }
    
#endif  // !os(macOS) && !os(tvOS) && !os(watchOS)
    
}
