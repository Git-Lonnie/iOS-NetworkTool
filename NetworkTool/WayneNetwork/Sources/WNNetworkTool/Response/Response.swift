//
//  Response.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 数据响应
public struct DataResponse<Success, Failure: Error> {
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let data: Data?
    public let metrics: URLSessionTaskMetrics?
    public let serializationDuration: TimeInterval
    public let result: Result<Success, Failure>
    
    public var value: Success? {
        return try? result.get()
    }
    
    public var error: Failure? {
        switch result {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                data: Data?,
                metrics: URLSessionTaskMetrics?,
                serializationDuration: TimeInterval,
                result: Result<Success, Failure>) {
        self.request = request
        self.response = response
        self.data = data
        self.metrics = metrics
        self.serializationDuration = serializationDuration
        self.result = result
    }
}

extension DataResponse: CustomStringConvertible {
    public var description: String {
        return """
        [Request]: \(request?.url?.absoluteString ?? "nil")
        [Response]: \(response?.statusCode ?? 0)
        [Data]: \(data?.count ?? 0) bytes
        [Result]: \(result)
        """
    }
}

extension DataResponse: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}

/// 下载响应
public struct DownloadResponse<Success, Failure: Error> {
    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public let fileURL: URL?
    public let resumeData: Data?
    public let metrics: URLSessionTaskMetrics?
    public let serializationDuration: TimeInterval
    public let result: Result<Success, Failure>
    
    public var value: Success? {
        return try? result.get()
    }
    
    public var error: Failure? {
        switch result {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                fileURL: URL?,
                resumeData: Data?,
                metrics: URLSessionTaskMetrics?,
                serializationDuration: TimeInterval,
                result: Result<Success, Failure>) {
        self.request = request
        self.response = response
        self.fileURL = fileURL
        self.resumeData = resumeData
        self.metrics = metrics
        self.serializationDuration = serializationDuration
        self.result = result
    }
}

