//
//  PBClient.swift
//
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation
import Socket
import SwiftyJSON

public struct PBClient {
    
    private let path: String
    private let queue: DispatchQueue
    
    public init(name: String, path: String) {
        self.path = path
        self.queue = DispatchQueue(label: name)
    }
    
    /// Send request to `PBServer` and receive response `JSON`.
    ///
    /// - Use `JSON(encode:)` and `JSON.decode(_:)` to convert to and from specific types.
    public func request(method: String?, payload: JSON) async throws -> JSON {
        try await withCheckedThrowingContinuation { continuation in
            request(method: method, payload: payload) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func request(method: String?, payload: JSON, completion: @escaping (Result<JSON, Error>) -> ()) {
        queue.async {
            do {
                let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
                try socket.connect(to: path)
                defer {
                    socket.close()
                }
                
                try writeRequest(socket, method: method, payload: payload)
                let (code, result) = try readResponse(socket)
                
                switch code {
                case .goodResponse:
                    completion(.success(result))
                default:
                    throw ServerError(json: result)
                }
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
}
