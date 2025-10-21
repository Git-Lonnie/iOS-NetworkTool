//
//  NetworkReachability.swift
//  WNNetworkTool
//
//  Created by WNNetworkTool
//

import Foundation
import SystemConfiguration

/// 网络可达性管理器
public class NetworkReachabilityManager {
    
    public enum NetworkReachabilityStatus {
        case unknown
        case notReachable
        case reachable(ConnectionType)
        
        public enum ConnectionType {
            case ethernetOrWiFi
            case cellular
        }
    }
    
    public typealias Listener = (NetworkReachabilityStatus) -> Void
    
    // MARK: - Properties
    
    public let host: String?
    public var listener: Listener?
    
    private var reachability: SCNetworkReachability?
    private var previousFlags: SCNetworkReachabilityFlags?
    
    private let reachabilityQueue = DispatchQueue(label: "com.wnnetworktool.reachabilityQueue")
    
    // MARK: - Initialization
    
    public convenience init?(host: String) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else {
            return nil
        }
        
        self.init(reachability: reachability, host: host)
    }
    
    public convenience init?() {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)
        
        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else {
            return nil
        }
        
        self.init(reachability: reachability, host: nil)
    }
    
    private init(reachability: SCNetworkReachability, host: String?) {
        self.reachability = reachability
        self.host = host
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Listening
    
    @discardableResult
    public func startListening(onQueue queue: DispatchQueue = .main, onUpdatePerforming listener: @escaping Listener) -> Bool {
        guard let reachability = reachability else { return false }
        
        stopListening()
        
        self.listener = listener
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            
            let manager = Unmanaged<NetworkReachabilityManager>.fromOpaque(info).takeUnretainedValue()
            manager.notifyListener(flags)
        }
        
        let queueAdded = SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue)
        let callbackAdded = SCNetworkReachabilitySetCallback(reachability, callback, &context)
        
        if queueAdded && callbackAdded {
            var flags = SCNetworkReachabilityFlags()
            if SCNetworkReachabilityGetFlags(reachability, &flags) {
                reachabilityQueue.async {
                    self.notifyListener(flags)
                }
            }
        }
        
        return queueAdded && callbackAdded
    }
    
    public func stopListening() {
        guard let reachability = reachability else { return }
        
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        
        listener = nil
    }
    
    // MARK: - Status
    
    public var status: NetworkReachabilityStatus {
        guard let reachability = reachability else { return .unknown }
        
        var flags = SCNetworkReachabilityFlags()
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else {
            return .unknown
        }
        
        return status(for: flags)
    }
    
    public var isReachable: Bool {
        switch status {
        case .reachable:
            return true
        default:
            return false
        }
    }
    
    public var isReachableOnCellular: Bool {
        switch status {
        case .reachable(.cellular):
            return true
        default:
            return false
        }
    }
    
    public var isReachableOnEthernetOrWiFi: Bool {
        switch status {
        case .reachable(.ethernetOrWiFi):
            return true
        default:
            return false
        }
    }
    
    // MARK: - Internal
    
    private func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        guard previousFlags != flags else { return }
        previousFlags = flags
        
        let status = self.status(for: flags)
        listener?(status)
    }
    
    private func status(for flags: SCNetworkReachabilityFlags) -> NetworkReachabilityStatus {
        guard flags.contains(.reachable) else { return .notReachable }
        
        var networkStatus: NetworkReachabilityStatus = .reachable(.ethernetOrWiFi)
        
        #if os(iOS) || os(tvOS)
        if flags.contains(.isWWAN) {
            networkStatus = .reachable(.cellular)
        }
        #endif
        
        return networkStatus
    }
}

// MARK: - NetworkReachabilityStatus Extension
extension NetworkReachabilityManager.NetworkReachabilityStatus: Equatable {
    public static func == (lhs: NetworkReachabilityManager.NetworkReachabilityStatus,
                          rhs: NetworkReachabilityManager.NetworkReachabilityStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.notReachable, .notReachable):
            return true
        case let (.reachable(lhsType), .reachable(rhsType)):
            return lhsType == rhsType
        default:
            return false
        }
    }
}

extension NetworkReachabilityManager.NetworkReachabilityStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .notReachable:
            return "Not Reachable"
        case .reachable(.ethernetOrWiFi):
            return "Reachable (Ethernet/WiFi)"
        case .reachable(.cellular):
            return "Reachable (Cellular)"
        }
    }
}

