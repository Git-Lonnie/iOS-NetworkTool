//
//  WNError.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// WNNetworkTool 错误类型
public enum WNError: Error {
    /// 参数编码失败
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    /// 参数编码器编码失败
    case parameterEncoderFailed(reason: ParameterEncoderFailureReason)
    /// 响应验证失败
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    /// 响应序列化失败
    case responseSerializationFailed(reason: ResponseSerializationFailureReason)
    /// 请求创建失败
    case createURLRequestFailed(error: Error)
    /// 请求重试失败
    case requestRetryFailed(retryError: Error, originalError: Error)
    /// 会话失效
    case sessionDeinitialized
    /// 会话任务失败
    case sessionTaskFailed(error: Error)
    /// 显式取消
    case explicitlyCancelled
    
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(error: Error)
        case customEncodingFailed(error: Error)
    }
    
    public enum ParameterEncoderFailureReason {
        case missingRequiredComponent(String)
        case encoderFailed(error: Error)
    }
    
    public enum ResponseValidationFailureReason {
        case dataFileNil
        case dataFileReadFailed(at: URL)
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)
        case customValidationFailed(error: Error)
    }
    
    public enum ResponseSerializationFailureReason {
        case inputDataNil
        case inputDataNilOrZeroLength
        case inputFileNil
        case inputFileReadFailed(at: URL)
        case stringSerializationFailed(encoding: String.Encoding)
        case jsonSerializationFailed(error: Error)
        case decodingFailed(error: Error)
        case customSerializationFailed(error: Error)
        case invalidEmptyResponse(type: String)
    }
}

extension WNError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parameterEncodingFailed(let reason):
            return "Parameter encoding failed: \(reason)"
        case .parameterEncoderFailed(let reason):
            return "Parameter encoder failed: \(reason)"
        case .responseValidationFailed(let reason):
            return "Response validation failed: \(reason)"
        case .responseSerializationFailed(let reason):
            return "Response serialization failed: \(reason)"
        case .createURLRequestFailed(let error):
            return "Create URL request failed: \(error.localizedDescription)"
        case .requestRetryFailed(let retryError, let originalError):
            return "Request retry failed: \(retryError.localizedDescription), original: \(originalError.localizedDescription)"
        case .sessionDeinitialized:
            return "Session deinitialized"
        case .sessionTaskFailed(let error):
            return "Session task failed: \(error.localizedDescription)"
        case .explicitlyCancelled:
            return "Request explicitly cancelled"
        }
    }
}

