//
//  Utils.swift
//
//
//  Created by Gong Zhang on 2024/4/17.
//

import Foundation
import SwiftyJSON

extension JSON {
    
    /// Encode value or object to `JSON`.
    public init<T: Encodable>(encode value: T) throws {
        let data = try JSONEncoder().encode(value)
        try self.init(data: data, options: .fragmentsAllowed)
    }
    
    /// Decode this `JSON` to value or object in specified type.
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: self.object, options: .fragmentsAllowed)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
}
