//
//  Validation.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 响应验证
extension DataRequest {
    
    public enum ValidationResult {
        case success
        case failure(Error)
    }
    
    @discardableResult
    public func validate(statusCode acceptableStatusCodes: Range<Int>) -> Self {
        return validate { _, response, _ in
            if acceptableStatusCodes.contains(response.statusCode) {
                return .success
            } else {
                let error = WNError.responseValidationFailed(
                    reason: .unacceptableStatusCode(code: response.statusCode)
                )
                return .failure(error)
            }
        }
    }
    
    @discardableResult
    public func validate(contentType acceptableContentTypes: [String]) -> Self {
        return validate { _, response, data in
            guard let contentType = response.mimeType else {
                let error = WNError.responseValidationFailed(
                    reason: .missingContentType(acceptableContentTypes: acceptableContentTypes)
                )
                return .failure(error)
            }
            
            for acceptableContentType in acceptableContentTypes {
                if contentType.contains(acceptableContentType) {
                    return .success
                }
            }
            
            let error = WNError.responseValidationFailed(
                reason: .unacceptableContentType(
                    acceptableContentTypes: acceptableContentTypes,
                    responseContentType: contentType
                )
            )
            return .failure(error)
        }
    }
    
    @discardableResult
    public func validate() -> Self {
        return validate(statusCode: 200..<300)
            .validate(contentType: ["application/json", "text/json", "text/html", "text/plain"])
    }
    
    @discardableResult
    public func validate(_ validation: @escaping (URLRequest?, HTTPURLResponse, Data?) -> ValidationResult) -> Self {
        // Validation logic would be called during response processing
        return self
    }
}

// MARK: - DownloadRequest Validation
extension DownloadRequest {
    
    public enum ValidationResult {
        case success
        case failure(Error)
    }
    
    @discardableResult
    public func validate(statusCode acceptableStatusCodes: Range<Int>) -> Self {
        return validate { _, response, _ in
            if acceptableStatusCodes.contains(response.statusCode) {
                return .success
            } else {
                let error = WNError.responseValidationFailed(
                    reason: .unacceptableStatusCode(code: response.statusCode)
                )
                return .failure(error)
            }
        }
    }
    
    @discardableResult
    public func validate() -> Self {
        return validate(statusCode: 200..<300)
    }
    
    @discardableResult
    public func validate(_ validation: @escaping (URLRequest?, HTTPURLResponse, URL?) -> ValidationResult) -> Self {
        // Validation logic would be called during response processing
        return self
    }
}

