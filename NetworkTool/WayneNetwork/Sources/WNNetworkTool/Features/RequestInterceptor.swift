//
//  RequestInterceptor.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 请求拦截器协议
public protocol RequestInterceptor: RequestAdapter & RequestRetrier {}

/// 请求适配器协议
public protocol RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
}

/// 请求重试协议
public protocol RequestRetrier {
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void)
}

/// 重试结果
public enum RetryResult {
    case retry
    case retryWithDelay(TimeInterval)
    case doNotRetry
    case doNotRetryWithError(Error)
}

/// 拦截器
public struct Interceptor: RequestInterceptor {
    public let adapters: [RequestAdapter]
    public let retriers: [RequestRetrier]
    
    public init(adapters: [RequestAdapter] = [], retriers: [RequestRetrier] = []) {
        self.adapters = adapters
        self.retriers = retriers
    }
    
    public init(adapter: RequestAdapter? = nil, retrier: RequestRetrier? = nil) {
        self.adapters = adapter.map { [$0] } ?? []
        self.retriers = retrier.map { [$0] } ?? []
    }
    
    // MARK: - RequestAdapter
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        adapt(urlRequest, for: session, using: adapters, completion: completion)
    }
    
    private func adapt(_ urlRequest: URLRequest,
                      for session: Session,
                      using adapters: [RequestAdapter],
                      completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var pendingAdapters = adapters
        
        guard !pendingAdapters.isEmpty else {
            completion(.success(urlRequest))
            return
        }
        
        let adapter = pendingAdapters.removeFirst()
        
        adapter.adapt(urlRequest, for: session) { result in
            switch result {
            case .success(let urlRequest):
                self.adapt(urlRequest, for: session, using: pendingAdapters, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - RequestRetrier
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        retry(request, for: session, dueTo: error, using: retriers, completion: completion)
    }
    
    private func retry(_ request: Request,
                      for session: Session,
                      dueTo error: Error,
                      using retriers: [RequestRetrier],
                      completion: @escaping (RetryResult) -> Void) {
        var pendingRetriers = retriers
        
        guard !pendingRetriers.isEmpty else {
            completion(.doNotRetry)
            return
        }
        
        let retrier = pendingRetriers.removeFirst()
        
        retrier.retry(request, for: session, dueTo: error) { result in
            switch result {
            case .retry, .retryWithDelay:
                completion(result)
            case .doNotRetry:
                self.retry(request, for: session, dueTo: error, using: pendingRetriers, completion: completion)
            case .doNotRetryWithError:
                completion(result)
            }
        }
    }
}

/// 重试策略
public struct RetryPolicy: RequestRetrier {
    
    public enum RetryableError {
        case connectionLost
        case timedOut
        case dnsLookupFailed
        case cannotFindHost
        case cannotConnectToHost
        case networkConnectionLost
        case notConnectedToInternet
        case secureConnectionFailed
        case serverCertificateHasBadDate
        case serverCertificateUntrusted
        case serverCertificateHasUnknownRoot
        case serverCertificateNotYetValid
        case clientCertificateRequired
        case clientCertificateRejected
    }
    
    public let retryLimit: Int
    public let exponentialBackoffBase: Int
    public let exponentialBackoffScale: Double
    public let retryableHTTPStatusCodes: Set<Int>
    public let retryableURLErrorCodes: Set<URLError.Code>
    
    public init(retryLimit: Int = 2,
                exponentialBackoffBase: Int = 2,
                exponentialBackoffScale: Double = 0.5,
                retryableHTTPStatusCodes: Set<Int> = [408, 500, 502, 503, 504],
                retryableURLErrorCodes: Set<URLError.Code> = [
                    .timedOut,
                    .cannotFindHost,
                    .cannotConnectToHost,
                    .networkConnectionLost,
                    .notConnectedToInternet,
                    .dnsLookupFailed
                ]) {
        self.retryLimit = retryLimit
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
        self.retryableHTTPStatusCodes = retryableHTTPStatusCodes
        self.retryableURLErrorCodes = retryableURLErrorCodes
    }
    
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // 简化版重试逻辑
        if let urlError = error as? URLError, retryableURLErrorCodes.contains(urlError.code) {
            let delay = pow(Double(exponentialBackoffBase), Double(1)) * exponentialBackoffScale
            completion(.retryWithDelay(delay))
        } else {
            completion(.doNotRetry)
        }
    }
}

