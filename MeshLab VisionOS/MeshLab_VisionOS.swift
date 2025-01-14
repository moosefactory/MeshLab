//
//  MeshLab_VisionOS.swift
//  MeshLab VisionOS
//
//  Created by Tristan Leblanc on 11/01/2025.
//

import AppIntents

struct MeshLab_VisionOS: AppIntent {
    static var title: LocalizedStringResource { "MeshLab VisionOS" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
