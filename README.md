# WNNetworkTool 国产国产国产！

WNNetworkTool 是一个功能强大的 Swift 网络库，模仿 Alamofire 设计，提供了优雅的 HTTP 网络请求接口。

## 特性

✨ **核心功能**
- 📡 支持所有 HTTP 方法（GET, POST, PUT, DELETE 等）
- 🔄 请求/响应拦截器
- 🔁 自动重试机制
- 📦 多种参数编码方式（URL 编码、JSON 编码）
- 📤 文件上传（支持 multipart/form-data）
- 📥 文件下载
- ✅ 响应验证
- 🎯 响应序列化（Data, String, JSON, Decodable）
- 🌐 网络可达性检测

## 系统要求

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.7+
- Xcode 14.0+

## 安装

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/Git-Lonnie/iOS-NetworkTool.git", from: "1.0.0")
]
```

或在 Xcode 中：
1. File > Add Packages...
2. 输入仓库 URL
3. 选择版本并添加到项目

## 使用指南

### 基础请求

```swift
import WNNetworkTool

// 简单的 GET 请求
WN.request("https://api.example.com/users")
    .responseJSON { response in
        switch response.result {
        case .success(let value):
            print("JSON: \(value)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }

// 带参数的 GET 请求
let parameters: Parameters = ["page": 1, "limit": 20]
WN.request("https://api.example.com/users",
          method: .get,
          parameters: parameters,
          encoding: URLEncoding.default)
    .responseJSON { response in
        print(response)
    }
```

### POST 请求

```swift
// JSON 编码的 POST 请求
let parameters: Parameters = [
    "username": "john_doe",
    "email": "john@example.com",
    "age": 30
]

WN.request("https://api.example.com/users",
          method: .post,
          parameters: parameters,
          encoding: JSONEncoding.default)
    .responseJSON { response in
        print(response)
    }
```

### 自定义 Headers

```swift
let headers: HTTPHeaders = [
    "Authorization": "Bearer your-token-here",
    "Content-Type": "application/json"
]

WN.request("https://api.example.com/protected",
          headers: headers)
    .responseJSON { response in
        print(response)
    }

// 或使用便捷方法
let headers2: HTTPHeaders = [
    .authorization(bearerToken: "your-token-here"),
    .accept("application/json")
]
```

### 响应处理

#### Data 响应

```swift
WN.request("https://api.example.com/data")
    .responseData { response in
        if let data = response.value {
            print("Data: \(data)")
        }
    }
```

#### String 响应

```swift
WN.request("https://api.example.com/text")
    .responseString { response in
        if let string = response.value {
            print("String: \(string)")
        }
    }
```

#### JSON 响应

```swift
WN.request("https://api.example.com/json")
    .responseJSON { response in
        if let json = response.value {
            print("JSON: \(json)")
        }
    }
```

#### Decodable 响应

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

WN.request("https://api.example.com/user/1")
    .responseDecodable(of: User.self) { response in
        switch response.result {
        case .success(let user):
            print("User: \(user.name)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
```

### 响应验证

```swift
// 验证状态码
WN.request("https://api.example.com/data")
    .validate(statusCode: 200..<300)
    .responseJSON { response in
        print(response)
    }

// 验证内容类型
WN.request("https://api.example.com/data")
    .validate(contentType: ["application/json"])
    .responseJSON { response in
        print(response)
    }

// 自动验证（状态码 200-299 + 内容类型）
WN.request("https://api.example.com/data")
    .validate()
    .responseJSON { response in
        print(response)
    }
```

### 文件下载

```swift
let destination: URL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("file.pdf")

WN.download("https://example.com/file.pdf",
           to: destination)
    .responseURL { response in
        if let fileURL = response.value {
            print("Downloaded to: \(fileURL)")
        }
    }
```

### 文件上传

#### 上传 Data

```swift
let data = "Hello, World!".data(using: .utf8)!

WN.upload(data, to: "https://api.example.com/upload")
    .responseJSON { response in
        print(response)
    }
```

#### 上传文件

```swift
let fileURL = Bundle.main.url(forResource: "photo", withExtension: "jpg")!

WN.upload(fileURL, to: "https://api.example.com/upload")
    .responseJSON { response in
        print(response)
    }
```

#### Multipart Form Data 上传

```swift
WN.upload(
    multipartFormData: { formData in
        // 添加文本字段
        formData.append("value1".data(using: .utf8)!, withName: "field1")
        
        // 添加文件
        if let imageURL = Bundle.main.url(forResource: "photo", withExtension: "jpg") {
            formData.append(imageURL, withName: "photo")
        }
        
        // 添加带文件名和 MIME 类型的文件
        if let fileURL = Bundle.main.url(forResource: "document", withExtension: "pdf") {
            formData.append(fileURL, withName: "document", fileName: "doc.pdf", mimeType: "application/pdf")
        }
    },
    to: "https://api.example.com/upload"
)
.responseJSON { response in
    print(response)
}
```

### 会话管理

```swift
// 使用自定义配置创建会话
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30
configuration.timeoutIntervalForResource = 300

let session = Session(configuration: configuration)

session.request("https://api.example.com/data")
    .responseJSON { response in
        print(response)
    }
```

### 请求拦截器

#### 请求适配器

```swift
class AuthenticationAdapter: RequestAdapter {
    private let token: String
    
    init(token: String) {
        self.token = token
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }
}

let adapter = AuthenticationAdapter(token: "your-token")
let interceptor = Interceptor(adapter: adapter)

WN.request("https://api.example.com/protected",
          interceptor: interceptor)
    .responseJSON { response in
        print(response)
    }
```

#### 请求重试器

```swift
let retryPolicy = RetryPolicy(
    retryLimit: 3,
    exponentialBackoffBase: 2,
    exponentialBackoffScale: 0.5
)

let interceptor = Interceptor(retrier: retryPolicy)

WN.request("https://api.example.com/data",
          interceptor: interceptor)
    .responseJSON { response in
        print(response)
    }
```

### 网络可达性

```swift
let manager = NetworkReachabilityManager()

manager?.startListening { status in
    switch status {
    case .unknown:
        print("Network status: Unknown")
    case .notReachable:
        print("Network status: Not Reachable")
    case .reachable(.ethernetOrWiFi):
        print("Network status: WiFi")
    case .reachable(.cellular):
        print("Network status: Cellular")
    }
}

// 检查当前状态
if manager?.isReachable == true {
    print("Network is reachable")
}

if manager?.isReachableOnCellular == true {
    print("Network is reachable on cellular")
}

// 停止监听
manager?.stopListening()
```

### 请求控制

```swift
let request = WN.request("https://api.example.com/data")
    .responseJSON { response in
        print(response)
    }

// 取消请求
request.cancel()

// 暂停请求
request.suspend()

// 恢复请求
request.resume()
```

## 高级用法

### 自定义参数编码

```swift
struct CustomEncoding: ParameterEncoding {
    func encode(_ urlRequest: URLRequest, with parameters: Parameters?) throws -> URLRequest {
        var request = urlRequest
        // 自定义编码逻辑
        return request
    }
}
```

### 自定义响应序列化器

```swift
struct CustomSerializer: ResponseSerializer {
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> CustomType {
        // 自定义序列化逻辑
        return customObject
    }
}
```

## API 对比

WNNetworkTool 与 Alamofire 的 API 对比：

| Alamofire | WNNetworkTool |
|-----------|---------------|
| `AF.request()` | `WN.request()` |
| `AF.download()` | `WN.download()` |
| `AF.upload()` | `WN.upload()` |
| `Session` | `Session` |
| `HTTPMethod` | `HTTPMethod` |
| `HTTPHeaders` | `HTTPHeaders` |
| `URLEncoding` | `URLEncoding` |
| `JSONEncoding` | `JSONEncoding` |
| `MultipartFormData` | `MultipartFormData` |
| `RequestInterceptor` | `RequestInterceptor` |
| `NetworkReachabilityManager` | `NetworkReachabilityManager` |

## 架构设计

```
WNNetworkTool
├── Core
│   ├── HTTPMethod.swift          // HTTP 方法定义
│   ├── HTTPHeaders.swift         // HTTP 头部管理
│   ├── WNError.swift             // 错误类型定义
│   ├── Request.swift             // 请求基类
│   └── Session.swift             // 会话管理器
├── Encoding
│   ├── ParameterEncoding.swift   // 参数编码协议和实现
│   └── ParameterEncoder.swift    // Encodable 参数编码器
├── Response
│   ├── Response.swift            // 响应数据结构
│   ├── ResponseSerialization.swift // 响应序列化器
│   └── Validation.swift          // 响应验证
├── Features
│   ├── MultipartFormData.swift   // 多部分表单数据
│   ├── RequestInterceptor.swift  // 请求拦截器
│   └── NetworkReachability.swift // 网络可达性检测
├── Extensions
│   ├── DataRequest+Response.swift    // 数据请求扩展
│   └── DownloadRequest+Response.swift // 下载请求扩展
└── WNNetworkTool.swift          // 主入口类
```

## 注意事项

1. **线程安全**：所有网络请求都是异步执行的，回调在主线程执行（除非另有指定）
2. **内存管理**：请求会自动管理生命周期，无需手动持有引用
3. **错误处理**：始终处理响应中的错误情况
4. **HTTPS**：推荐使用 HTTPS 协议，确保数据传输安全

## 性能优化建议

1. 使用 `Session` 单例以复用连接
2. 合理设置超时时间
3. 对大文件使用下载/上传任务，而不是普通请求
4. 实现响应缓存策略
5. 使用 `Decodable` 代替手动 JSON 解析

## 许可证

MIT License

## 作者

WNNetworkTool - 一个模仿 Alamofire 的 Swift 网络库

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

### 1.0.0
- 🎉 初始版本发布
- ✅ 完整实现 Alamofire 核心功能
- 📚 完善文档和示例代码

如果好用你可以支持下我吗？我将持续维护它！

<p align="center">
  <img src="wx.jpg" width="300" alt="微信赞赏码" />
  <img src="zfb.jpg" width="300" alt="支付宝收款码" />
</p>

有问题联系QQ:540378725
