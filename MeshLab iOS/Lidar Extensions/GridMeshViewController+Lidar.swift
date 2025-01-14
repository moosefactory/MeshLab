//
//  GridMeshViewController+Lidar.swift
//  TerrainMesh
//
//  Created by Tristan Leblanc on 05/01/2025.
//

import Foundation

#if !os(macOS) && !os(tvOS)

extension GridMeshViewController {
    
    func startLidar() {
                
        let lidarCameraManager = CameraManager { error in
            print("Can't start Lidar - \(error)")
            self.isLidarAvailable = false
        }

        if !isLidarAvailable {
            return
        }
                                               
        self.lidarCameraManager = lidarCameraManager
        
        DispatchQueue.global(qos: .background).async {
            lidarCameraManager.resumeStream()
        }
        
        lidarCameraManager.$dataAvailable.sink { [self] value in
            let data = lidarCameraManager.capturedData
            if value {

                DispatchQueue.main.async { [self] in
                    lidarCameraManager.processingCapturedResult = true
                    //gridMeshSceneController.lidarData = data
                    lidarCameraManager.processingCapturedResult = false
                }

            }
        }.store(in: &listeners)
        
        lidarCameraManager.$processingCapturedResult.sink { [self] value in
            let data = lidarCameraManager.capturedData
            if value {

                DispatchQueue.main.async { [self] in
                    lidarCameraManager.processingCapturedResult = true
                    //print("RECEIVE LIDAR $dataAvailable \(value)")
                   // gridMeshSceneController.lidarData = data
                    lidarCameraManager.processingCapturedResult = false
                }

            }

            
        }.store(in: &listeners)
        
        lidarCameraManager.$waitingForCapture.sink { value in
            print("$waitingForCapture \(value)")
        }.store(in: &listeners)
    }

}

#endif
