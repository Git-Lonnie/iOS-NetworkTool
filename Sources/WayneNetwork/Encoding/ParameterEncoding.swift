//
//  ParameterEncoding.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 参数编码协议
public protocol ParameterEncoding {
    func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest
}

public typealias Parameters = [String: Any]

// MARK: - URLEncoding
public struct URLEncoding: ParameterEncoding {
    
    public enum Destination {
        case methodDependent
        case queryString
        case httpBody
    }
    
    public enum ArrayEncoding {
        case brackets
        case noBrackets
    }
    
    public enum BoolEncoding {
        case numeric
        case literal
    }
    
    public static var `default`: URLEncoding { return URLEncoding() }
    public static var queryString: URLEncoding { return URLEncoding(destination: .queryString) }
    public static var httpBody: URLEncoding { return URLEncoding(destination: .httpBody) }
    
    public let destination: Destination
    public let arrayEncoding: ArrayEncoding
    public let boolEncoding: BoolEncoding
    
    public init(destination: Destination = .methodDependent,
                arrayEncoding: ArrayEncoding = .brackets,
                boolEncoding: BoolEncoding = .numeric) {
        self.destination = destination
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }
    
    public func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest {
        var request = urlRequest
        
        guard let parameters = parameters else { return request }
        
        if let method = HTTPMethod(rawValue: request.httpMethod ?? "GET") {
            let encodingDestination = resolveDestination(for: method)
            
            switch encodingDestination {
            case .queryString:
                if let url = request.url {
                    if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                        urlComponents.percentEncodedQuery = percentEncodedQuery
                        request.url = urlComponents.url
                    }
                }
            case .httpBody:
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                }
                request.httpBody = Data(query(parameters).utf8)
            case .methodDependent:
                // 这不应该发生
                break
            }
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
    
    private func query(_ parameters: Parameters) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    private func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .wnURLQueryAllowed) ?? string
    }
}

extension URLEncoding.ArrayEncoding {
    func encode(key: String) -> String {
        switch self {
        case .brackets:
            return "\(key)[]"
        case .noBrackets:
            return key
        }
    }
}

extension URLEncoding.BoolEncoding {
    func encode(value: Bool) -> String {
        switch self {
        case .numeric:
            return value ? "1" : "0"
        case .literal:
            return value ? "true" : "false"
        }
    }
}

// MARK: - JSONEncoding
public struct JSONEncoding: ParameterEncoding {
    
    public static var `default`: JSONEncoding { return JSONEncoding() }
    public static var prettyPrinted: JSONEncoding { return JSONEncoding(options: .prettyPrinted) }
    
    public let options: JSONSerialization.WritingOptions
    
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }
    
    public func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest {
        var request = urlRequest
        
        guard let parameters = parameters else { return request }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: options)
            
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            
            request.httpBody = data
        } catch {
            throw WNError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
        
        return request
    }
}

// MARK: - CharacterSet Extension
extension CharacterSet {
    static let wnURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

