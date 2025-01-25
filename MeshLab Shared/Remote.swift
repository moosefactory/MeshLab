//
//  MeshLabRemotes.swift
//  MeshLab
//
//  Created by Tristan Leblanc on 06/01/2025.
//

import Foundation
import MFFoundation
import MFRemotes

class Remote: MFRemotesAPIProtocol {
    
    /// The objects that are sent by the remotes
    struct Action: Equatable, JSONCodable {
        var identifier: String
        
        static let start = Remote.Action(identifier: "start")
        static let randomize = Remote.Action(identifier: "Randomize")
        static let handshake = Remote.Action(identifier: "handshake")
    }
    
    func prepareRemoteConfigurationData() -> Data? {
        do {
            return try Action.handshake.json()
        }
        catch {
            print("Error")
        }
        return nil
    }
    
    public var actionHandler: ((Action)->Void)?

    public init(actionHandler: ((Action)->Void)? = nil) {
        self.actionHandler = actionHandler
    }
    
    public lazy var dataHandler: ((Data) -> Void) = { [weak self] data in
        do {
            self?.actionHandler?(try Action.make(with: data))
        }
        catch {
            print(error)
        }
    }
}
