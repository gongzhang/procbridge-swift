//
//  Const.swift
//
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation

let pbFlag = Data("pb".utf8)

enum ProtocolVersion {
    case v1_1

    static let current: Self = .v1_1
    
    var binary: Data {
        switch self {
        case .v1_1:
            var data = Data(capacity: 2)
            data.append(1 as UInt8)
            data.append(1 as UInt8)
            return data
        }
    }
}

enum StatusCode: UInt8 {
    case request = 0
    case goodResponse = 1
    case badResponse = 2
}

enum PayloadKeys: String {
    case method = "method"
    case payload = "payload"
    case message = "message"
}
