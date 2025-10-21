//
//  DownloadRequest+Response.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

extension DownloadRequest {
    
    // MARK: - Response Handler
    
    @discardableResult
    public func response(queue: DispatchQueue = .main,
                        completionHandler: @escaping (DownloadResponse<URL?, Error>) -> Void) -> Self {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        task?.resume()
        
        // 等待任务完成
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            while !self.isFinished && !self.isCancelled {
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let serializationDuration = endTime - startTime
            
            let result: Result<URL?, Error>
            if let error = self.error {
                result = .failure(error)
            } else {
                result = .success(self.fileURL)
            }
            
            let response = DownloadResponse<URL?, Error>(
                request: self.task?.originalRequest,
                response: self.task?.response as? HTTPURLResponse,
                fileURL: self.fileURL,
                resumeData: nil,
                metrics: nil,
                serializationDuration: serializationDuration,
                result: result
            )
            
            queue.async {
                completionHandler(response)
            }
        }
        
        return self
    }
    
    // MARK: - Download Response
    
    @discardableResult
    public func responseURL(queue: DispatchQueue = .main,
                           completionHandler: @escaping (DownloadResponse<URL, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<URL, Error>
            
            switch response.result {
            case .success(let url):
                if let url = url {
                    result = .success(url)
                } else {
                    result = .failure(WNError.responseSerializationFailed(reason: .inputFileNil))
                }
            case .failure(let error):
                result = .failure(error)
            }
            
            let urlResponse = DownloadResponse<URL, Error>(
                request: response.request,
                response: response.response,
                fileURL: response.fileURL,
                resumeData: response.resumeData,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(urlResponse)
        }
    }
    
    // MARK: - Data Response
    
    @discardableResult
    public func responseData(queue: DispatchQueue = .main,
                            completionHandler: @escaping (DownloadResponse<Data, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<Data, Error>
            
            switch response.result {
            case .success(let url):
                if let url = url {
                    do {
                        let data = try Data(contentsOf: url)
                        result = .success(data)
                    } catch {
                        result = .failure(WNError.responseSerializationFailed(reason: .inputFileReadFailed(at: url)))
                    }
                } else {
                    result = .failure(WNError.responseSerializationFailed(reason: .inputFileNil))
                }
            case .failure(let error):
                result = .failure(error)
            }
            
            let dataResponse = DownloadResponse<Data, Error>(
                request: response.request,
                response: response.response,
                fileURL: response.fileURL,
                resumeData: response.resumeData,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(dataResponse)
        }
    }
}

