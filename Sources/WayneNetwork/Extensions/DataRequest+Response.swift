//
//  DataRequest+Response.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

extension DataRequest {
    
    // MARK: - Response Handler
    
    @discardableResult
    public func response(queue: DispatchQueue = .main,
                        completionHandler: @escaping (DataResponse<Data?, Error>) -> Void) -> Self {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        task?.resume()
        
        // 等待任务完成
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 简单的同步等待任务完成（生产环境应使用更复杂的异步处理）
            while !self.isFinished && !self.isCancelled {
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let serializationDuration = endTime - startTime
            
            let result: Result<Data?, Error>
            if let error = self.error {
                result = .failure(error)
            } else {
                result = .success(self.data())
            }
            
            let response = DataResponse<Data?, Error>(
                request: self.task?.originalRequest,
                response: self.task?.response as? HTTPURLResponse,
                data: self.data(),
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
    
    // MARK: - Data Response
    
    @discardableResult
    public func responseData(queue: DispatchQueue = .main,
                            completionHandler: @escaping (DataResponse<Data, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<Data, Error>
            
            switch response.result {
            case .success(let data):
                if let data = data {
                    result = .success(data)
                } else {
                    result = .failure(WNError.responseSerializationFailed(reason: .inputDataNil))
                }
            case .failure(let error):
                result = .failure(error)
            }
            
            let dataResponse = DataResponse<Data, Error>(
                request: response.request,
                response: response.response,
                data: response.data,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(dataResponse)
        }
    }
    
    // MARK: - String Response
    
    @discardableResult
    public func responseString(queue: DispatchQueue = .main,
                              encoding: String.Encoding? = nil,
                              completionHandler: @escaping (DataResponse<String, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<String, Error>
            
            do {
                let serializer = StringResponseSerializer(encoding: encoding)
                let string = try serializer.serialize(
                    request: response.request,
                    response: response.response,
                    data: response.data,
                    error: response.error
                )
                result = .success(string)
            } catch {
                result = .failure(error)
            }
            
            let stringResponse = DataResponse<String, Error>(
                request: response.request,
                response: response.response,
                data: response.data,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(stringResponse)
        }
    }
    
    // MARK: - JSON Response
    
    @discardableResult
    public func responseJSON(queue: DispatchQueue = .main,
                            options: JSONSerialization.ReadingOptions = .allowFragments,
                            completionHandler: @escaping (DataResponse<Any, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<Any, Error>
            
            do {
                let serializer = JSONResponseSerializer(options: options)
                let json = try serializer.serialize(
                    request: response.request,
                    response: response.response,
                    data: response.data,
                    error: response.error
                )
                result = .success(json)
            } catch {
                result = .failure(error)
            }
            
            let jsonResponse = DataResponse<Any, Error>(
                request: response.request,
                response: response.response,
                data: response.data,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(jsonResponse)
        }
    }
    
    // MARK: - Decodable Response
    
    @discardableResult
    public func responseDecodable<T: Decodable>(of type: T.Type = T.self,
                                                queue: DispatchQueue = .main,
                                                decoder: DataDecoder = JSONDecoder(),
                                                completionHandler: @escaping (DataResponse<T, Error>) -> Void) -> Self {
        return response(queue: queue) { response in
            let result: Result<T, Error>
            
            do {
                let serializer = DecodableResponseSerializer<T>(decoder: decoder)
                let decoded = try serializer.serialize(
                    request: response.request,
                    response: response.response,
                    data: response.data,
                    error: response.error
                )
                result = .success(decoded)
            } catch {
                result = .failure(error)
            }
            
            let decodableResponse = DataResponse<T, Error>(
                request: response.request,
                response: response.response,
                data: response.data,
                metrics: response.metrics,
                serializationDuration: response.serializationDuration,
                result: result
            )
            
            completionHandler(decodableResponse)
        }
    }
}

