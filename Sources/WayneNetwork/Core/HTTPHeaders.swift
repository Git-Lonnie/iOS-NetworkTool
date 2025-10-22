//
//  HTTPHeaders.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// HTTP 请求头封装
public struct HTTPHeaders {
    private var headers: [HTTPHeader] = []
    
    public init() {}
    
    public init(_ headers: [HTTPHeader]) {
        self.headers = headers
    }
    
    public init(_ dictionary: [String: String]) {
        self.init(dictionary.map { HTTPHeader(name: $0.key, value: $0.value) })
    }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements.map { HTTPHeader(name: $0.0, value: $0.1) })
    }
}

extension HTTPHeaders: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: HTTPHeader...) {
        self.init(elements)
    }
}

extension HTTPHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[HTTPHeader]> {
        return headers.makeIterator()
    }
}

extension HTTPHeaders: Collection {
    public var startIndex: Int {
        return headers.startIndex
    }
    
    public var endIndex: Int {
        return headers.endIndex
    }
    
    public subscript(position: Int) -> HTTPHeader {
        return headers[position]
    }
    
    public func index(after i: Int) -> Int {
        return headers.index(after: i)
    }
}

extension HTTPHeaders: CustomStringConvertible {
    public var description: String {
        return headers.map { "\($0.name): \($0.value)" }.joined(separator: "\n")
    }
}

extension HTTPHeaders {
    public mutating func add(name: String, value: String) {
        headers.append(HTTPHeader(name: name, value: value))
    }
    
    public mutating func add(_ header: HTTPHeader) {
        headers.append(header)
    }
    
    public mutating func update(name: String, value: String) {
        if let index = headers.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
            headers[index] = HTTPHeader(name: name, value: value)
        } else {
            headers.append(HTTPHeader(name: name, value: value))
        }
    }
    
    public mutating func update(_ header: HTTPHeader) {
        update(name: header.name, value: header.value)
    }
    
    public mutating func remove(name: String) {
        headers.removeAll { $0.name.lowercased() == name.lowercased() }
    }
    
    public func value(for name: String) -> String? {
        return headers.first { $0.name.lowercased() == name.lowercased() }?.value
    }
    
    public subscript(_ name: String) -> String? {
        get { return value(for: name) }
        set {
            if let value = newValue {
                update(name: name, value: value)
            } else {
                remove(name: name)
            }
        }
    }
    
    public var dictionary: [String: String] {
        var dict: [String: String] = [:]
        headers.forEach { dict[$0.name] = $0.value }
        return dict
    }
}

// MARK: - HTTPHeader
public struct HTTPHeader {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Common Headers
extension HTTPHeader {
    public static func accept(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Accept", value: value)
    }
    
    public static func acceptCharset(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Accept-Charset", value: value)
    }
    
    public static func acceptLanguage(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Accept-Language", value: value)
    }
    
    public static func acceptEncoding(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Accept-Encoding", value: value)
    }
    
    public static func authorization(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Authorization", value: value)
    }
    
    public static func authorization(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return authorization("Basic \(credential)")
    }
    
    public static func authorization(bearerToken: String) -> HTTPHeader {
        return authorization("Bearer \(bearerToken)")
    }
    
    public static func contentDisposition(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Content-Disposition", value: value)
    }
    
    public static func contentType(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "Content-Type", value: value)
    }
    
    public static func userAgent(_ value: String) -> HTTPHeader {
        return HTTPHeader(name: "User-Agent", value: value)
    }
}

// MARK: - Default Headers
extension HTTPHeaders {
    public static let `default`: HTTPHeaders = [
        .accept("*/*"),
        .acceptEncoding("br;q=1.0, gzip;q=0.8, deflate;q=0.6"),
        .acceptLanguage("en-US,en;q=0.9"),
        .userAgent(HTTPHeaders.defaultUserAgent)
    ]
    
    public static let defaultUserAgent: String = {
        let info = Bundle.main.infoDictionary
        let executable = (info?["CFBundleExecutable"] as? String) ??
                        (ProcessInfo.processInfo.arguments.first?.split(separator: "/").last.map(String.init)) ??
                        "Unknown"
        let bundle = (info?["CFBundleIdentifier"] as? String) ?? "Unknown"
        let appVersion = (info?["CFBundleShortVersionString"] as? String) ?? "Unknown"
        let appBuild = (info?["CFBundleVersion"] as? String) ?? "Unknown"
        
        let osNameVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            let osName: String
            #if os(iOS)
            osName = "iOS"
            #elseif os(watchOS)
            osName = "watchOS"
            #elseif os(tvOS)
            osName = "tvOS"
            #elseif os(macOS)
            osName = "macOS"
            #elseif os(Linux)
            osName = "Linux"
            #elseif os(Windows)
            osName = "Windows"
            #else
            osName = "Unknown"
            #endif
            return "\(osName) \(versionString)"
        }()
        
        return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"
    }()
}

