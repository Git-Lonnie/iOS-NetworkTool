//
//  Request.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation

/// 请求基类
open class Request {
    
    public let id: UUID
    public let session: URLSession
    public var task: URLSessionTask?
    
    public var error: Error?
    
    private var taskDelegate: TaskDelegate?
    
    var eventMonitor: EventMonitor?
    
    private var mutableState = MutableState()
    
    private struct MutableState {
        var isFinished = false
        var isCancelled = false
        var responseData: Data?
    }
    
    init(id: UUID = UUID(), session: URLSession, task: URLSessionTask?) {
        self.id = id
        self.session = session
        self.task = task
    }
    
    // MARK: - State
    
    open var isFinished: Bool {
        return mutableState.isFinished
    }
    
    open var isCancelled: Bool {
        return mutableState.isCancelled
    }
    
    // MARK: - Lifecycle
    
    func didCreateTask(_ task: URLSessionTask) {
        self.task = task
    }
    
    func didComplete(task: URLSessionTask, with error: Error?) {
        self.error = error
        mutableState.isFinished = true
    }
    
    func didReceive(data: Data) {
        if mutableState.responseData == nil {
            mutableState.responseData = data
        } else {
            mutableState.responseData?.append(data)
        }
    }
    
    // MARK: - Control
    
    @discardableResult
    open func cancel() -> Self {
        guard !isCancelled else { return self }
        
        mutableState.isCancelled = true
        task?.cancel()
        
        return self
    }
    
    @discardableResult
    open func suspend() -> Self {
        task?.suspend()
        return self
    }
    
    @discardableResult
    open func resume() -> Self {
        task?.resume()
        return self
    }
}

// MARK: - DataRequest
open class DataRequest: Request {
    
    struct Requestable {
        let urlRequest: URLRequest
    }
    
    var requestable: Requestable?
    
    private var mutableData = Data()
    
    override func didReceive(data: Data) {
        super.didReceive(data: data)
        mutableData.append(data)
    }
    
    func data() -> Data? {
        return mutableData
    }
}

// MARK: - DownloadRequest
open class DownloadRequest: Request {
    
    public var fileURL: URL?
    
    override func didComplete(task: URLSessionTask, with error: Error?) {
        super.didComplete(task: task, with: error)
        
        if let downloadTask = task as? URLSessionDownloadTask,
           let location = (downloadTask as? URLSessionDownloadTaskProtocol)?.downloadedFileURL {
            self.fileURL = location
        }
    }
}

private protocol URLSessionDownloadTaskProtocol {
    var downloadedFileURL: URL? { get }
}

// MARK: - UploadRequest
open class UploadRequest: DataRequest {
    
    public enum Uploadable {
        case data(Data)
        case file(URL)
        case stream(InputStream)
    }
    
    public var upload: Uploadable?
}

// MARK: - TaskDelegate
class TaskDelegate: NSObject {
    
    var data: Data = Data()
    var error: Error?
    
    weak var request: Request?
    
    init(request: Request) {
        self.request = request
    }
}

// MARK: - EventMonitor
public protocol EventMonitor {
    func requestDidResume(_ request: Request)
    func requestDidSuspend(_ request: Request)
    func requestDidCancel(_ request: Request)
    func requestDidFinish(_ request: Request)
    func request(_ request: Request, didFailWith error: Error)
    func request(_ request: DataRequest, didReceive data: Data)
}

extension EventMonitor {
    public func requestDidResume(_ request: Request) {}
    public func requestDidSuspend(_ request: Request) {}
    public func requestDidCancel(_ request: Request) {}
    public func requestDidFinish(_ request: Request) {}
    public func request(_ request: Request, didFailWith error: Error) {}
    public func request(_ request: DataRequest, didReceive data: Data) {}
}

