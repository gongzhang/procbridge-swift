//
//  Protocol.swift
//
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation
import Socket
import SwiftyJSON

func readBytes(_ socket: Socket, count: Int) throws -> Data {
    assert(count > 0)
    var data = Data(count: count)
    let len: Int = try data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
        let buffer = pointer.bindMemory(to: CChar.self)
        return try socket.read(into: buffer.baseAddress!, bufSize: count, truncate: true)
    }
    return data.prefix(len)
}

func readSocket(_ socket: Socket) throws -> (StatusCode, JSON) {
    // 1. FLAG 'pb'
    let flag = try readBytes(socket, count: 2)
    guard flag == pbFlag else {
        throw ProtocolError.unrecognizedProtocol
    }
    
    // 2. VERSION
    let version = try readBytes(socket, count: 2)
    guard version == ProtocolVersion.current.binary else {
        throw ProtocolError.incompatibleVersion
    }
    
    // 3. STATUS CODE
    let statusCode = try readBytes(socket, count: 1)
    guard statusCode.count == 1 else {
        throw ProtocolError.incompleteData
    }
    
    guard let code = StatusCode(rawValue: statusCode[0]) else {
        throw ProtocolError.unrecognizedProtocol
    }
    
    // 4. RESERVED (2 bytes)
    guard try readBytes(socket, count: 2).count == 2 else {
        throw ProtocolError.incompleteData
    }

    // 5. LENGTH (4-byte, little endian)
    let lenBytes = try readBytes(socket, count: 4)
    guard lenBytes.count == 4 else {
        throw ProtocolError.incompleteData
    }
    let jsonLen = (lenBytes.withUnsafeBytes { $0.load(as: UInt32.self) }).littleEndian

    // 6. JSON OBJECT
    let jsonBytes = try readBytes(socket, count: Int(jsonLen))
    guard jsonBytes.count == jsonLen else {
        throw ProtocolError.incompleteData
    }
    
    let json: JSON
    do {
        json = try JSON(data: jsonBytes)
    } catch {
        throw ProtocolError.invalidBody
    }
    
    return (code, json)
}

func writeSocket(_ socket: Socket, statusCode: StatusCode, json: JSON) throws {
    // 1. FLAG
    try socket.write(from: pbFlag)
    
    // 2. VERSION
    try socket.write(from: ProtocolVersion.current.binary)
    
    // 3. STATUS CODE
    try socket.write(from: Data([statusCode.rawValue]))
    
    // 4. RESERVED 2 BYTES
    try socket.write(from: Data([0x00, 0x00]))
    
    // 5. LENGTH (little endian)
    let jsonData = try json.rawData()
    var jsonLength = UInt32(jsonData.count).littleEndian
    let lengthData = Data(bytes: &jsonLength, count: MemoryLayout<UInt32>.size)
    try socket.write(from: lengthData)
    
    // 6. JSON
    try socket.write(from: jsonData)
}

func writeRequest(_ socket: Socket, method: String?, payload: JSON) throws {
    var body: JSON = [:]
    if let method {
        body[PayloadKeys.method.rawValue].stringValue = method
    }
    if payload.type != .null {
        body[PayloadKeys.payload.rawValue] = payload
    }
    try writeSocket(socket, statusCode: .request, json: body)
}

func writeGoodResponse(_ socket: Socket, payload: JSON) throws {
    var body: JSON = [:]
    if payload.type != .null {
        body[PayloadKeys.payload.rawValue] = payload
    }
    try writeSocket(socket, statusCode: .goodResponse, json: body)
}

func writeBadResponse(_ socket: Socket, message: String?) throws {
    var body: JSON = [:]
    if let message {
        body[PayloadKeys.message.rawValue].stringValue = message
    }
    try writeSocket(socket, statusCode: .badResponse, json: body)
}

func readRequest(_ socket: Socket) throws -> (String?, JSON) {
    let (statusCode, obj) = try readSocket(socket)
    guard statusCode == .request else {
        throw ProtocolError.invalidStatusCode
    }
    let method = obj[PayloadKeys.method.rawValue].string
    let payload = obj[PayloadKeys.payload.rawValue]
    return (method, payload)
}

func readResponse(_ socket: Socket) throws -> (StatusCode, JSON) {
    let (statusCode, obj) = try readSocket(socket)
    switch statusCode {
    case .goodResponse:
        let payload = obj[PayloadKeys.payload.rawValue]
        return (.goodResponse, payload)
    case .badResponse:
        let message = obj[PayloadKeys.message.rawValue].string ?? "unknown server error"
        return (.badResponse, JSON(message))
    case .request:
        throw ProtocolError.invalidStatusCode
    }
}
