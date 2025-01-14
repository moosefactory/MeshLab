//
//  Model.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 10/01/2025.
//

/// The MeshLab Application model
///
/// - FunctionsParams defines an animation that is applied to the mesh
/// 

struct FunctionParams {
    
    var speedAttenuationFactor = 0.999999
    var attenuationFactor = 0.9999999
    var maxHeight = 8.0
    var timeScale = 1.0           // Multiplicator applied to angle
    var scale = 20.0           // Multiplicator applied to angle
    var exponent = 2.0        // Damping from the center
    var exponentStart = 1.1       // Damping from the center
    var dampingScale = 8.0    // The damping scale
    var distanceToCenterStart = 0.1 // Added to the distance from center to avoid division by zero and smooth the center area
    
    static func random() -> FunctionParams {
        FunctionParams(speedAttenuationFactor: .random(min: 0.99999, max: 0.999999),
                       attenuationFactor: .random(min: 0.99999, max: 0.9999999),
                       maxHeight: 1 + .random(8),
                       timeScale: 0.9 + .random(0.3),
                       scale: 0.5 + .random(40),
                       exponent: 1.0 + .random(0.2),
                       exponentStart: 0.9 + .random(0.3),
                       dampingScale: 1.0 + .random(8),
                       distanceToCenterStart: 0.08 + .random(1.5))
    }
}
