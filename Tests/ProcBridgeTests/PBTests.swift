import XCTest
import SwiftyJSON
@testable import ProcBridge

final class PBTests: XCTestCase {
    
    static var server: PBServer!
    static let path: String = "/tmp/procbridge-unittest.sock"
    
    override class func setUp() {
        server = PBServer(name: "TestServer", path: path) { method, payload in
            switch method {
            case "echo":
                return payload
                
            case "sum":
                let sum: Double = payload.arrayValue
                    .compactMap {
                        $0.double
                    }
                    .reduce(0.0, +)
                return JSON(sum)
                
            default:
                throw ServerError(message: "unknown method")
            }
        }
        Task {
            try await server.start()
        }
    }
    
    override class func tearDown() {
        let server = server
        self.server = nil
        Task {
            try await server?.stop()
        }
    }
    
    func testEcho() async throws {
        let client = PBClient(name: "TestClient", path: Self.path)
        let resp = try await client.request(method: "echo", payload: "hello!")
        XCTAssertEqual(resp, "hello!")
    }
    
    func testSum() async throws {
        let client = PBClient(name: "TestClient", path: Self.path)
        let resp = try await client.request(method: "sum", payload: JSON([1, 2, 3, 4]))
        XCTAssertEqual(resp, JSON(10))
    }
    
    func testError() async throws {
        let client = PBClient(name: "TestClient", path: Self.path)
        do {
            _ = try await client.request(method: "unknown method", payload: .null)
            XCTFail()
        } catch let error as ServerError {
            XCTAssertEqual(error.message, "unknown method")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
