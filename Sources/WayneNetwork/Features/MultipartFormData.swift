//
//  MultipartFormData.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
import MobileCoreServices
#elseif os(macOS)
import CoreServices
#endif

/// 多部分表单数据
open class MultipartFormData {
    
    struct EncodingCharacters {
        static let crlf = "\r\n"
    }
    
    struct BoundaryGenerator {
        static func randomBoundary() -> String {
            let first = UInt32.random(in: UInt32.min...UInt32.max)
            let second = UInt32.random(in: UInt32.min...UInt32.max)
            return String(format: "wnnetworktool.boundary.%08x%08x", first, second)
        }
    }
    
    public let boundary: String
    
    private var bodyParts: [BodyPart] = []
    private var bodyPartError: Error?
    
    public var contentType: String {
        return "multipart/form-data; boundary=\(boundary)"
    }
    
    public init() {
        self.boundary = BoundaryGenerator.randomBoundary()
    }
    
    // MARK: - Body Parts
    
    public func append(_ data: Data, withName name: String) {
        let headers = contentHeaders(withName: name)
        let bodyPart = BodyPart(headers: headers, bodyStream: InputStream(data: data), bodyContentLength: UInt64(data.count))
        bodyParts.append(bodyPart)
    }
    
    public func append(_ data: Data, withName name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        let bodyPart = BodyPart(headers: headers, bodyStream: InputStream(data: data), bodyContentLength: UInt64(data.count))
        bodyParts.append(bodyPart)
    }
    
    public func append(_ fileURL: URL, withName name: String) {
        let fileName = fileURL.lastPathComponent
        let mimeType = mimeType(forPathExtension: fileURL.pathExtension)
        
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64 ?? 0
            let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
            
            guard let stream = InputStream(url: fileURL) else {
                bodyPartError = WNError.parameterEncodingFailed(reason: .missingURL)
                return
            }
            
            let bodyPart = BodyPart(headers: headers, bodyStream: stream, bodyContentLength: fileSize)
            bodyParts.append(bodyPart)
        } catch {
            bodyPartError = error
        }
    }
    
    public func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String) {
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64 ?? 0
            let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
            
            guard let stream = InputStream(url: fileURL) else {
                bodyPartError = WNError.parameterEncodingFailed(reason: .missingURL)
                return
            }
            
            let bodyPart = BodyPart(headers: headers, bodyStream: stream, bodyContentLength: fileSize)
            bodyParts.append(bodyPart)
        } catch {
            bodyPartError = error
        }
    }
    
    public func append(_ stream: InputStream, withLength length: UInt64, name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        let bodyPart = BodyPart(headers: headers, bodyStream: stream, bodyContentLength: length)
        bodyParts.append(bodyPart)
    }
    
    // MARK: - Encoding
    
    public func encode() throws -> Data {
        if let error = bodyPartError {
            throw error
        }
        
        var data = Data()
        
        for bodyPart in bodyParts {
            let bodyPartData = try encode(bodyPart)
            data.append(bodyPartData)
        }
        
        data.append(
            BoundaryGenerator.boundaryData(forBoundaryType: .final, boundary: boundary)
        )
        
        return data
    }
    
    private func encode(_ bodyPart: BodyPart) throws -> Data {
        var data = Data()
        
        let initialBoundary = BoundaryGenerator.boundaryData(forBoundaryType: .initial, boundary: boundary)
        data.append(initialBoundary)
        
        let headerData = encodeHeaders(for: bodyPart)
        data.append(headerData)
        
        let bodyStreamData = try encodeBodyStream(for: bodyPart)
        data.append(bodyStreamData)
        
        return data
    }
    
    private func encodeHeaders(for bodyPart: BodyPart) -> Data {
        var headerText = ""
        
        for (key, value) in bodyPart.headers {
            headerText += "\(key): \(value)\(EncodingCharacters.crlf)"
        }
        headerText += EncodingCharacters.crlf
        
        return Data(headerText.utf8)
    }
    
    private func encodeBodyStream(for bodyPart: BodyPart) throws -> Data {
        let stream = bodyPart.bodyStream
        stream.open()
        defer { stream.close() }
        
        var data = Data()
        
        while stream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = stream.read(&buffer, maxLength: 1024)
            
            if let error = stream.streamError {
                throw error
            }
            
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            }
        }
        
        return data
    }
    
    // MARK: - Content Headers
    
    private func contentHeaders(withName name: String, fileName: String? = nil, mimeType: String? = nil) -> [String: String] {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName {
            disposition += "; filename=\"\(fileName)\""
        }
        
        var headers = ["Content-Disposition": disposition]
        if let mimeType = mimeType {
            headers["Content-Type"] = mimeType
        }
        
        return headers
    }
    
    private func mimeType(forPathExtension pathExtension: String) -> String {
        // 使用新的 UniformTypeIdentifiers (iOS 14+, macOS 11+)
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            #if canImport(UniformTypeIdentifiers)
            if let utType = UTType(filenameExtension: pathExtension) {
                return utType.preferredMIMEType ?? "application/octet-stream"
            }
            #endif
        }
        
        // 旧版本使用 MobileCoreServices/CoreServices
        #if os(iOS) || os(tvOS) || os(watchOS)
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
           let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }
        #elseif os(macOS)
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
           let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }
        #endif
        
        // 回退到常见的 MIME 类型映射
        return mimeTypeMapping[pathExtension.lowercased()] ?? "application/octet-stream"
    }
    
    // 常见文件扩展名的 MIME 类型映射
    private let mimeTypeMapping: [String: String] = [
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "gif": "image/gif",
        "bmp": "image/bmp",
        "webp": "image/webp",
        "svg": "image/svg+xml",
        "pdf": "application/pdf",
        "json": "application/json",
        "xml": "application/xml",
        "txt": "text/plain",
        "html": "text/html",
        "css": "text/css",
        "js": "text/javascript",
        "mp4": "video/mp4",
        "mov": "video/quicktime",
        "avi": "video/x-msvideo",
        "mp3": "audio/mpeg",
        "wav": "audio/wav",
        "zip": "application/zip",
        "rar": "application/x-rar-compressed",
        "7z": "application/x-7z-compressed",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    ]
    
    // MARK: - Private - Body Part
    
    struct BodyPart {
        let headers: [String: String]
        let bodyStream: InputStream
        let bodyContentLength: UInt64
    }
}

// MARK: - BoundaryGenerator Extension
extension MultipartFormData.BoundaryGenerator {
    enum BoundaryType {
        case initial
        case final
    }
    
    static func boundaryData(forBoundaryType boundaryType: BoundaryType, boundary: String) -> Data {
        let boundaryText: String
        
        switch boundaryType {
        case .initial:
            boundaryText = "--\(boundary)\(MultipartFormData.EncodingCharacters.crlf)"
        case .final:
            boundaryText = "--\(boundary)--\(MultipartFormData.EncodingCharacters.crlf)"
        }
        
        return Data(boundaryText.utf8)
    }
}

