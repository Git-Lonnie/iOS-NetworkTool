# 快速入门指南

WNNetworkTool 是一个功能强大、易于使用的 Swift 网络库。本指南将帮助你在 5 分钟内上手。

## 安装

### Swift Package Manager

在 Xcode 中：

1. 打开你的项目
2. 选择 `File` > `Add Packages...`
3. 输入仓库 URL
4. 选择版本并添加

或在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/iOS-NetworkTool.git", from: "1.0.0")
]
```

## 第一个请求

### 导入库

```swift
import WNNetworkTool
```

### 发送 GET 请求

```swift
WN.request("https://api.example.com/users")
    .responseJSON { response in
        print(response)
    }
```

就这么简单！🎉

## 常用场景

### 1. 获取 JSON 数据

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

WN.request("https://api.example.com/users/1")
    .responseDecodable(of: User.self) { response in
        switch response.result {
        case .success(let user):
            print("👤 \(user.name)")
        case .failure(let error):
            print("❌ \(error)")
        }
    }
```

### 2. POST 请求提交数据

```swift
let parameters: Parameters = [
    "username": "john_doe",
    "email": "john@example.com"
]

WN.request("https://api.example.com/users",
          method: .post,
          parameters: parameters,
          encoding: JSONEncoding.default)
    .responseJSON { response in
        print(response)
    }
```

### 3. 添加请求头（如 Token）

```swift
let headers: HTTPHeaders = [
    .authorization(bearerToken: "your-token-here")
]

WN.request("https://api.example.com/protected",
          headers: headers)
    .responseJSON { response in
        print(response)
    }
```

### 4. 下载文件

```swift
let destination = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("file.pdf")

WN.download("https://example.com/file.pdf", to: destination)
    .responseURL { response in
        if let fileURL = response.value {
            print("📥 Downloaded: \(fileURL)")
        }
    }
```

### 5. 上传图片

```swift
WN.upload(
    multipartFormData: { formData in
        // 添加图片
        formData.append(imageData, withName: "photo", fileName: "photo.jpg", mimeType: "image/jpeg")
        
        // 添加其他字段
        formData.append("Caption text".data(using: .utf8)!, withName: "caption")
    },
    to: "https://api.example.com/upload"
)
.responseJSON { response in
    print("✅ Upload complete")
}
```

### 6. 检测网络状态

```swift
let manager = NetworkReachabilityManager()

manager?.startListening { status in
    switch status {
    case .reachable(.ethernetOrWiFi):
        print("📶 WiFi 已连接")
    case .reachable(.cellular):
        print("📱 使用蜂窝数据")
    case .notReachable:
        print("❌ 无网络连接")
    case .unknown:
        print("❓ 网络状态未知")
    }
}
```

## 进阶功能

### 请求验证

```swift
WN.request("https://api.example.com/data")
    .validate()  // 自动验证状态码 200-299
    .responseJSON { response in
        // 如果状态码不在 200-299，会返回错误
        print(response)
    }
```

### 自定义会话

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30

let session = Session(configuration: configuration)

session.request("https://api.example.com/data")
    .responseJSON { response in
        print(response)
    }
```

### 请求拦截器（自动添加 Token）

```swift
class AuthAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer token", forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }
}

let interceptor = Interceptor(adapter: AuthAdapter())
WN.request("https://api.example.com/protected", interceptor: interceptor)
    .responseJSON { response in
        print(response)
    }
```

## API 速查表

| 功能 | 方法 |
|------|------|
| GET 请求 | `WN.request(url)` |
| POST 请求 | `WN.request(url, method: .post, parameters: params)` |
| 下载文件 | `WN.download(url, to: destination)` |
| 上传文件 | `WN.upload(fileURL, to: url)` |
| 上传表单 | `WN.upload(multipartFormData: { ... }, to: url)` |
| JSON 响应 | `.responseJSON { }` |
| Decodable 响应 | `.responseDecodable(of: Type.self) { }` |
| 字符串响应 | `.responseString { }` |
| 数据响应 | `.responseData { }` |
| 验证响应 | `.validate()` |
| 取消请求 | `request.cancel()` |

## 常见问题

### Q: 如何处理请求超时？

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30  // 30 秒超时

let session = Session(configuration: configuration)
```

### Q: 如何添加全局请求头？

```swift
let configuration = URLSessionConfiguration.default
configuration.httpAdditionalHeaders = [
    "Content-Type": "application/json",
    "X-API-Version": "v1"
]

let session = Session(configuration: configuration)
```

### Q: 如何处理 SSL 证书？

```swift
// 使用自定义的 URLSessionDelegate
// 详见完整文档
```

### Q: 如何调试网络请求？

```swift
// 1. 查看完整响应
WN.request(url).response { response in
    print("Request: \(response.request)")
    print("Response: \(response.response)")
    print("Data: \(response.data)")
    print("Error: \(response.error)")
}

// 2. 使用事件监听器
class Logger: EventMonitor {
    func requestDidResume(_ request: Request) {
        print("🟢 Request started")
    }
}
```

## 下一步

- 📖 阅读 [完整文档](README.md)
- 💻 查看 [示例代码](Examples/)
- 🧪 运行 [单元测试](Tests/)
- 🎯 学习 [高级用法](README.md#高级用法)

## 获取帮助

- 💬 提交 [Issue](https://github.com/yourusername/iOS-NetworkTool/issues)
- 📧 发送邮件至 support@example.com
- 📚 查阅 [API 文档](https://yourusername.github.io/iOS-NetworkTool/)

---

**Happy Coding! 🚀**

