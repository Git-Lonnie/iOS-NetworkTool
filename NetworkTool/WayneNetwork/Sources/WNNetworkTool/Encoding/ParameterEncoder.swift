//
//  ParameterEncoder.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 参数编码器协议
public protocol ParameterEncoder {
    func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest
}

// MARK: - JSONParameterEncoder
public struct JSONParameterEncoder: ParameterEncoder {
    
    public static var `default`: JSONParameterEncoder { return JSONParameterEncoder() }
    public static var prettyPrinted: JSONParameterEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return JSONParameterEncoder(encoder: encoder)
    }
    
    public let encoder: JSONEncoder
    
    public init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }
    
    public func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest {
        guard let parameters = parameters else { return request }
        
        var request = request
        
        do {
            let data = try encoder.encode(parameters)
            
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            request.httpBody = data
        } catch {
            throw WNError.parameterEncoderFailed(reason: .encoderFailed(error: error))
        }
        
        return request
    }
}

// MARK: - URLEncodedFormParameterEncoder
public struct URLEncodedFormParameterEncoder: ParameterEncoder {
    
    public static var `default`: URLEncodedFormParameterEncoder { return URLEncodedFormParameterEncoder() }
    
    public let encoder: URLEncodedFormEncoder
    public let destination: Destination
    
    public enum Destination {
        case methodDependent
        case queryString
        case httpBody
    }
    
    public init(encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), destination: Destination = .methodDependent) {
        self.encoder = encoder
        self.destination = destination
    }
    
    public func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest {
        guard let parameters = parameters else { return request }
        
        var request = request
        
        guard let url = request.url else {
            throw WNError.parameterEncoderFailed(reason: .missingRequiredComponent("URL"))
        }
        
        guard let method = request.httpMethod.flatMap({ HTTPMethod(rawValue: $0) }) else {
            let httpMethod = request.httpMethod ?? "nil"
            throw WNError.parameterEncoderFailed(reason: .missingRequiredComponent("HTTPMethod: \(httpMethod)"))
        }
        
        let resolvedDestination = resolveDestination(for: method)
        
        do {
            let encoded = try encoder.encode(parameters)
            
            switch resolvedDestination {
            case .queryString:
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    throw WNError.parameterEncoderFailed(reason: .missingRequiredComponent("URLComponents"))
                }
                components.percentEncodedQuery = encoded
                request.url = components.url
                
            case .httpBody:
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                }
                request.httpBody = Data(encoded.utf8)
                
            case .methodDependent:
                // 这不应该发生，因为 resolveDestination 会解析它
                break
            }
        } catch {
            throw WNError.parameterEncoderFailed(reason: .encoderFailed(error: error))
        }
        
        return request
    }
    
    private func resolveDestination(for method: HTTPMethod) -> Destination {
        switch destination {
        case .methodDependent:
            return [.get, .head, .delete].contains(method) ? .queryString : .httpBody
        default:
            return destination
        }
    }
}

// MARK: - URLEncodedFormEncoder
public struct URLEncodedFormEncoder {
    
    public init() {}
    
    public func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = _URLEncodedFormEncoder()
        try value.encode(to: encoder)
        return encoder.result
    }
}

private class _URLEncodedFormEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    
    var result = ""
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        let container = KeyedContainer<Key>(encoder: self, codingPath: codingPath)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainer(encoder: self, codingPath: codingPath)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainer(encoder: self, codingPath: codingPath)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: _URLEncodedFormEncoder
        var codingPath: [CodingKey]
        
        mutating func encodeNil(forKey key: Key) throws {}
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
            let keyString = key.stringValue
            let valueString = "\(value)"
            addToResult(key: keyString, value: valueString)
        }
        
        private mutating func addToResult(key: String, value: String) {
            if !encoder.result.isEmpty {
                encoder.result += "&"
            }
            encoder.result += "\(escape(key))=\(escape(value))"
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
        
        private func escape(_ string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: .wnURLQueryAllowed) ?? string
        }
    }
    
    private struct UnkeyedContainer: UnkeyedEncodingContainer {
        let encoder: _URLEncodedFormEncoder
        var codingPath: [CodingKey]
        var count: Int = 0
        
        mutating func encodeNil() throws {}
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            try value.encode(to: encoder)
            count += 1
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
    }
    
    private struct SingleValueContainer: SingleValueEncodingContainer {
        let encoder: _URLEncodedFormEncoder
        var codingPath: [CodingKey]
        
        mutating func encodeNil() throws {}
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            encoder.result = "\(value)"
        }
    }
}

