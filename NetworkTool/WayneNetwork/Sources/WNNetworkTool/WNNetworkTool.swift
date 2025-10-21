//
//  WNNetworkTool.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// WNNetworkTool 主类 - 提供便捷的静态方法
public struct WN {
    
    /// 默认会话
    public static let sessionManager = Session.default
    
    // MARK: - Request
    
    @discardableResult
    public static func request(_ url: URLConvertible,
                              method: HTTPMethod = .get,
                              parameters: Parameters? = nil,
                              encoding: ParameterEncoding = URLEncoding.default,
                              headers: HTTPHeaders? = nil,
                              interceptor: RequestInterceptor? = nil) -> DataRequest {
        return sessionManager.request(url,
                                     method: method,
                                     parameters: parameters,
                                     encoding: encoding,
                                     headers: headers,
                                     interceptor: interceptor)
    }
    
    @discardableResult
    public static func request(_ convertible: URLRequestConvertible,
                              interceptor: RequestInterceptor? = nil) -> DataRequest {
        return sessionManager.request(convertible, interceptor: interceptor)
    }
    
    // MARK: - Download
    
    @discardableResult
    public static func download(_ url: URLConvertible,
                               method: HTTPMethod = .get,
                               parameters: Parameters? = nil,
                               encoding: ParameterEncoding = URLEncoding.default,
                               headers: HTTPHeaders? = nil,
                               to destination: URL? = nil,
                               interceptor: RequestInterceptor? = nil) -> DownloadRequest {
        return sessionManager.download(url,
                                      method: method,
                                      parameters: parameters,
                                      encoding: encoding,
                                      headers: headers,
                                      to: destination,
                                      interceptor: interceptor)
    }
    
    @discardableResult
    public static func download(_ convertible: URLRequestConvertible,
                               to destination: URL? = nil,
                               interceptor: RequestInterceptor? = nil) -> DownloadRequest {
        return sessionManager.download(convertible, to: destination, interceptor: interceptor)
    }
    
    // MARK: - Upload
    
    @discardableResult
    public static func upload(_ data: Data,
                             to convertible: URLRequestConvertible,
                             interceptor: RequestInterceptor? = nil) -> UploadRequest {
        return sessionManager.upload(data, to: convertible, interceptor: interceptor)
    }
    
    @discardableResult
    public static func upload(_ fileURL: URL,
                             to convertible: URLRequestConvertible,
                             interceptor: RequestInterceptor? = nil) -> UploadRequest {
        return sessionManager.upload(fileURL, to: convertible, interceptor: interceptor)
    }
    
    @discardableResult
    public static func upload(multipartFormData: @escaping (MultipartFormData) -> Void,
                             to url: URLConvertible,
                             method: HTTPMethod = .post,
                             headers: HTTPHeaders? = nil,
                             interceptor: RequestInterceptor? = nil) -> UploadRequest {
        return sessionManager.upload(multipartFormData: multipartFormData,
                                    to: url,
                                    method: method,
                                    headers: headers,
                                    interceptor: interceptor)
    }
}

