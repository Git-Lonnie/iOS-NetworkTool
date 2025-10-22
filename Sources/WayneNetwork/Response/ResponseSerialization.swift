//
//  ResponseSerialization.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 响应序列化器协议
public protocol ResponseSerializer {
    associatedtype SerializedObject
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> SerializedObject
}

/// 数据响应序列化器
public struct DataResponseSerializer: ResponseSerializer {
    
    public static var `default`: DataResponseSerializer {
        return DataResponseSerializer()
    }
    
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public init(emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<HTTPMethod> = [.head]) {
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Data {
        if let error = error {
            throw error
        }
        
        guard let data = data, !data.isEmpty else {
            guard let response = response else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            let isEmptyResponse = emptyResponseCodes.contains(response.statusCode)
            let isEmptyRequestMethod = request?.httpMethod.flatMap { HTTPMethod(rawValue: $0) }.map { emptyRequestMethods.contains($0) } ?? false
            
            if isEmptyResponse || isEmptyRequestMethod {
                return Data()
            } else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
        }
        
        return data
    }
}

/// 字符串响应序列化器
public struct StringResponseSerializer: ResponseSerializer {
    
    public static var `default`: StringResponseSerializer {
        return StringResponseSerializer()
    }
    
    public let encoding: String.Encoding?
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public init(encoding: String.Encoding? = nil,
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<HTTPMethod> = [.head]) {
        self.encoding = encoding
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> String {
        if let error = error {
            throw error
        }
        
        guard let data = data, !data.isEmpty else {
            guard let response = response else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            let isEmptyResponse = emptyResponseCodes.contains(response.statusCode)
            let isEmptyRequestMethod = request?.httpMethod.flatMap { HTTPMethod(rawValue: $0) }.map { emptyRequestMethods.contains($0) } ?? false
            
            if isEmptyResponse || isEmptyRequestMethod {
                return ""
            } else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
        }
        
        let encoding = self.encoding ?? response?.textEncoding ?? .utf8
        
        guard let string = String(data: data, encoding: encoding) else {
            throw WNError.responseSerializationFailed(reason: .stringSerializationFailed(encoding: encoding))
        }
        
        return string
    }
}

/// JSON 响应序列化器
public struct JSONResponseSerializer: ResponseSerializer {
    
    public static var `default`: JSONResponseSerializer {
        return JSONResponseSerializer()
    }
    
    public let options: JSONSerialization.ReadingOptions
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public init(options: JSONSerialization.ReadingOptions = .allowFragments,
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<HTTPMethod> = [.head]) {
        self.options = options
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Any {
        if let error = error {
            throw error
        }
        
        guard let data = data, !data.isEmpty else {
            guard let response = response else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            let isEmptyResponse = emptyResponseCodes.contains(response.statusCode)
            let isEmptyRequestMethod = request?.httpMethod.flatMap { HTTPMethod(rawValue: $0) }.map { emptyRequestMethods.contains($0) } ?? false
            
            if isEmptyResponse || isEmptyRequestMethod {
                return NSNull()
            } else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
        }
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: options)
        } catch {
            throw WNError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error))
        }
    }
}

/// Decodable 响应序列化器
public struct DecodableResponseSerializer<T: Decodable>: ResponseSerializer {
    
    public let decoder: DataDecoder
    public let emptyResponseCodes: Set<Int>
    public let emptyRequestMethods: Set<HTTPMethod>
    
    public init(decoder: DataDecoder = JSONDecoder(),
                emptyResponseCodes: Set<Int> = [204, 205],
                emptyRequestMethods: Set<HTTPMethod> = [.head]) {
        self.decoder = decoder
        self.emptyResponseCodes = emptyResponseCodes
        self.emptyRequestMethods = emptyRequestMethods
    }
    
    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        if let error = error {
            throw error
        }
        
        guard let data = data, !data.isEmpty else {
            guard let response = response else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
            
            let isEmptyResponse = emptyResponseCodes.contains(response.statusCode)
            let isEmptyRequestMethod = request?.httpMethod.flatMap { HTTPMethod(rawValue: $0) }.map { emptyRequestMethods.contains($0) } ?? false
            
            if isEmptyResponse || isEmptyRequestMethod {
                // 尝试创建空值
                if T.self is String.Type {
                    return ("" as! T)
                } else if T.self is [Any].Type {
                    return ([] as! T)
                } else if T.self is [String: Any].Type {
                    return ([:] as! T)
                } else {
                    throw WNError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "\(T.self)"))
                }
            } else {
                throw WNError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
            }
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw WNError.responseSerializationFailed(reason: .decodingFailed(error: error))
        }
    }
}

// MARK: - DataDecoder Protocol
public protocol DataDecoder {
    func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D
}

extension JSONDecoder: DataDecoder {}

// MARK: - Empty Protocol
public protocol Empty {
    static var value: Self { get }
}

extension String: Empty {
    public static var value: String { return "" }
}

extension Array: Empty {
    public static var value: Array { return [] }
}

extension Dictionary: Empty {
    public static var value: Dictionary { return [:] }
}

// MARK: - HTTPURLResponse Extension
extension HTTPURLResponse {
    var textEncoding: String.Encoding? {
        guard let encodingName = textEncodingName else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        ))
    }
}

