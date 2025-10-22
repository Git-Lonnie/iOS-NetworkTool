//
//  Session.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 会话管理器
open class Session {
    
    public static let `default` = Session(configuration: .default)
    
    public let session: URLSession
    public let rootQueue: DispatchQueue
    public let requestQueue: DispatchQueue
    public let serializationQueue: DispatchQueue
    
    public let interceptor: RequestInterceptor?
    public let eventMonitors: [EventMonitor]
    
    private var requests: [UUID: Request] = [:]
    private let requestsLock = NSLock()
    
    // MARK: - Initialization
    
    public init(session: URLSession,
                interceptor: RequestInterceptor? = nil,
                eventMonitors: [EventMonitor] = []) {
        self.session = session
        self.interceptor = interceptor
        self.eventMonitors = eventMonitors
        
        self.rootQueue = DispatchQueue(label: "com.wnnetworktool.rootQueue")
        self.requestQueue = DispatchQueue(label: "com.wnnetworktool.requestQueue")
        self.serializationQueue = DispatchQueue(label: "com.wnnetworktool.serializationQueue")
    }
    
    public convenience init(configuration: URLSessionConfiguration = .default,
                           interceptor: RequestInterceptor? = nil,
                           eventMonitors: [EventMonitor] = []) {
        let session = URLSession(configuration: configuration)
        self.init(session: session, interceptor: interceptor, eventMonitors: eventMonitors)
    }
    
    // MARK: - Request
    
    @discardableResult
    open func request(_ convertible: URLRequestConvertible,
                     interceptor: RequestInterceptor? = nil) -> DataRequest {
        let request = DataRequest(session: session, task: nil)
        
        requestQueue.async {
            do {
                let urlRequest = try convertible.asURLRequest()
                let task = self.session.dataTask(with: urlRequest)
                request.didCreateTask(task)
                
                self.storeRequest(request)
                
                task.resume()
                
                self.eventMonitors.forEach { $0.requestDidResume(request) }
            } catch {
                request.didComplete(task: request.task!, with: error)
            }
        }
        
        return request
    }
    
    @discardableResult
    open func request(_ url: URLConvertible,
                     method: HTTPMethod = .get,
                     parameters: Parameters? = nil,
                     encoding: ParameterEncoding = URLEncoding.default,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil) -> DataRequest {
        do {
            let request = try URLRequest(url: url, method: method, headers: headers)
            let encodedRequest = try encoding.encode(request, with: parameters)
            return self.request(encodedRequest, interceptor: interceptor)
        } catch {
            let failedRequest = DataRequest(session: session, task: nil)
            requestQueue.async {
                failedRequest.didComplete(task: failedRequest.task!, with: error)
            }
            return failedRequest
        }
    }
    
    // MARK: - Download
    
    @discardableResult
    open func download(_ convertible: URLRequestConvertible,
                      to destination: URL? = nil,
                      interceptor: RequestInterceptor? = nil) -> DownloadRequest {
        let request = DownloadRequest(session: session, task: nil)
        
        requestQueue.async {
            do {
                let urlRequest = try convertible.asURLRequest()
                let task = self.session.downloadTask(with: urlRequest)
                request.didCreateTask(task)
                
                self.storeRequest(request)
                
                task.resume()
                
                self.eventMonitors.forEach { $0.requestDidResume(request) }
            } catch {
                request.didComplete(task: request.task!, with: error)
            }
        }
        
        return request
    }
    
    @discardableResult
    open func download(_ url: URLConvertible,
                      method: HTTPMethod = .get,
                      parameters: Parameters? = nil,
                      encoding: ParameterEncoding = URLEncoding.default,
                      headers: HTTPHeaders? = nil,
                      to destination: URL? = nil,
                      interceptor: RequestInterceptor? = nil) -> DownloadRequest {
        do {
            let request = try URLRequest(url: url, method: method, headers: headers)
            let encodedRequest = try encoding.encode(request, with: parameters)
            return self.download(encodedRequest, to: destination, interceptor: interceptor)
        } catch {
            let failedRequest = DownloadRequest(session: session, task: nil)
            requestQueue.async {
                failedRequest.didComplete(task: failedRequest.task!, with: error)
            }
            return failedRequest
        }
    }
    
    // MARK: - Upload
    
    @discardableResult
    open func upload(_ data: Data,
                    to convertible: URLRequestConvertible,
                    interceptor: RequestInterceptor? = nil) -> UploadRequest {
        let request = UploadRequest(session: session, task: nil)
        request.upload = .data(data)
        
        requestQueue.async {
            do {
                let urlRequest = try convertible.asURLRequest()
                let task = self.session.uploadTask(with: urlRequest, from: data)
                request.didCreateTask(task)
                
                self.storeRequest(request)
                
                task.resume()
                
                self.eventMonitors.forEach { $0.requestDidResume(request) }
            } catch {
                request.didComplete(task: request.task!, with: error)
            }
        }
        
        return request
    }
    
    @discardableResult
    open func upload(_ fileURL: URL,
                    to convertible: URLRequestConvertible,
                    interceptor: RequestInterceptor? = nil) -> UploadRequest {
        let request = UploadRequest(session: session, task: nil)
        request.upload = .file(fileURL)
        
        requestQueue.async {
            do {
                let urlRequest = try convertible.asURLRequest()
                let task = self.session.uploadTask(with: urlRequest, fromFile: fileURL)
                request.didCreateTask(task)
                
                self.storeRequest(request)
                
                task.resume()
                
                self.eventMonitors.forEach { $0.requestDidResume(request) }
            } catch {
                request.didComplete(task: request.task!, with: error)
            }
        }
        
        return request
    }
    
    @discardableResult
    open func upload(multipartFormData: @escaping (MultipartFormData) -> Void,
                    to url: URLConvertible,
                    method: HTTPMethod = .post,
                    headers: HTTPHeaders? = nil,
                    interceptor: RequestInterceptor? = nil) -> UploadRequest {
        let formData = MultipartFormData()
        multipartFormData(formData)
        
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
            
            let data = try formData.encode()
            return upload(data, to: urlRequest, interceptor: interceptor)
        } catch {
            let failedRequest = UploadRequest(session: session, task: nil)
            requestQueue.async {
                failedRequest.didComplete(task: failedRequest.task!, with: error)
            }
            return failedRequest
        }
    }
    
    // MARK: - Internal
    
    private func storeRequest(_ request: Request) {
        requestsLock.lock()
        requests[request.id] = request
        requestsLock.unlock()
    }
    
    private func removeRequest(_ request: Request) {
        requestsLock.lock()
        requests.removeValue(forKey: request.id)
        requestsLock.unlock()
    }
}

// MARK: - URLConvertible
public protocol URLConvertible {
    func asURL() throws -> URL
}

extension String: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw WNError.parameterEncodingFailed(reason: .missingURL)
        }
        return url
    }
}

extension URL: URLConvertible {
    public func asURL() throws -> URL {
        return self
    }
}

extension URLComponents: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = url else {
            throw WNError.parameterEncodingFailed(reason: .missingURL)
        }
        return url
    }
}

// MARK: - URLRequestConvertible
public protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}

extension URLRequest: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        return self
    }
}

extension URLRequest {
    public init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()
        self.init(url: url)
        
        httpMethod = method.rawValue
        
        if let headers = headers {
            for header in headers {
                setValue(header.value, forHTTPHeaderField: header.name)
            }
        }
    }
}

