//
//  Error.swift
//  
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation
import SwiftyJSON

public enum ProtocolError: Error, LocalizedError {
    case unrecognizedProtocol
    case incompatibleVersion
    case incompleteData
    case invalidStatusCode
    case invalidBody
    case unknownServerError
    
    public var errorDescription: String? {
        switch self {
        case .unrecognizedProtocol:
            "unrecognized protocol"
        case .incompatibleVersion:
            "incompatible protocol version"
        case .incompleteData:
            "incomplete data"
        case .invalidStatusCode:
            "invalid status code"
        case .invalidBody:
            "invalid body"
        case .unknownServerError:
            "unknown server error"
        }
    }
}

public struct ServerError: Error, LocalizedError {
    
    public var message: String
    
    public init(message: String) {
        self.message = message
    }
    
    init(json: JSON) {
        self.init(message: json.string ?? "unknown server error")
    }
    
    public var errorDescription: String? {
        message
    }
    
}
