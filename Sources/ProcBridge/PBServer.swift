//
//  PBServer.swift
//  
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation
import Socket
import SwiftyJSON

public class PBServer: @unchecked Sendable {
    
    public typealias Handler = (_ method: String?, _ payload: JSON) async throws -> JSON
    
    private let path: String
    private let queue: DispatchQueue
    private let handler: Handler
    
    private var socket: Socket?
    
    public init(name: String, path: String, handler: @escaping Handler) {
        self.path = path
        self.queue = DispatchQueue(label: name)
        self.handler = handler
    }
    
    public func start() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.start { result in
                continuation.resume(with: result)
            }
        }
    }
    
    public func stop() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.stop { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func start(completion: @escaping (Result<Void, Error>) -> ()) {
        queue.async { [self] in
            guard socket == nil else {
                completion(.failure(ServerError(message: "server already started")))
                return
            }
            
            do {
                let socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
                try socket.listen(on: path)
                self.socket = socket
                
                // loop
                DispatchQueue.global().async {
                    do {
                        repeat {
                            let client = try socket.acceptClientConnection()
                            DispatchQueue.global().async {
                                // hand a call
                                do {
                                    let (method, payload) = try readRequest(client)
                                    Task {
                                        do {
                                            let result = try await self.handler(method, payload)
                                            try? writeGoodResponse(client, payload: result)
                                        } catch {
                                            try? writeBadResponse(client, message: error.localizedDescription)
                                        }
                                        client.close()
                                    }
                                } catch {
                                    assertionFailure(error.localizedDescription)
                                }
                            }
                        } while true
                    } catch {
                    }
                }
                
                completion(.success(()))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func stop(completion: @escaping (Result<Void, Error>) -> ()) {
        queue.async { [self] in
            guard let socket else {
                completion(.failure(ServerError(message: "server is not started")))
                return
            }
            
            socket.close()
            self.socket = nil
            completion(.success(()))
        }
    }
    
}
