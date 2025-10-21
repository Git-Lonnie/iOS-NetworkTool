# 贡献指南

感谢你对 WNNetworkTool 的关注！我们欢迎各种形式的贡献。

## 贡献方式

你可以通过以下方式为项目做出贡献：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 💻 提交代码
- 🧪 编写测试
- 🌍 翻译文档

## 开发环境设置

### 要求

- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+
- Git

### 克隆项目

```bash
git clone https://github.com/yourusername/iOS-NetworkTool.git
cd iOS-NetworkTool
```

### 打开项目

```bash
# 使用 Xcode 打开
open Package.swift

# 或使用命令行编译
swift build
```

### 运行测试

```bash
swift test
```

## 代码规范

### Swift 代码风格

我们遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)。

**主要规则：**

1. 使用 4 空格缩进（不使用 Tab）
2. 每行代码不超过 120 字符
3. 使用有意义的变量名
4. 添加适当的注释
5. 使用 `// MARK: -` 组织代码

**示例：**

```swift
// MARK: - Properties

public let session: URLSession
private var requests: [UUID: Request] = [:]

// MARK: - Initialization

public init(session: URLSession) {
    self.session = session
}

// MARK: - Public Methods

public func request(_ url: URLConvertible) -> DataRequest {
    // Implementation
}

// MARK: - Private Methods

private func handleResponse(_ response: URLResponse) {
    // Implementation
}
```

### 命名规范

- **类/结构体/枚举**：大驼峰命名法（PascalCase）
  ```swift
  class SessionManager { }
  struct HTTPHeader { }
  enum HTTPMethod { }
  ```

- **方法/变量/常量**：小驼峰命名法（camelCase）
  ```swift
  func makeRequest() { }
  let requestTimeout = 30
  var isConnected = false
  ```

- **协议**：使用形容词或名词
  ```swift
  protocol RequestAdapter { }
  protocol URLConvertible { }
  ```

### 文档注释

为公共 API 添加文档注释：

```swift
/// 发送 HTTP 请求
///
/// - Parameters:
///   - url: 请求的 URL
///   - method: HTTP 方法
///   - parameters: 请求参数
/// - Returns: DataRequest 实例
public func request(_ url: URLConvertible,
                   method: HTTPMethod = .get,
                   parameters: Parameters? = nil) -> DataRequest {
    // Implementation
}
```

## 提交代码

### 分支策略

- `main` - 稳定版本
- `develop` - 开发分支
- `feature/*` - 新功能分支
- `bugfix/*` - Bug 修复分支
- `hotfix/*` - 紧急修复分支

### 工作流程

1. **Fork 项目**

   在 GitHub 上 Fork 项目到你的账号。

2. **创建分支**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **编写代码**

   - 遵循代码规范
   - 添加必要的测试
   - 更新文档

4. **提交更改**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **推送分支**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**

   在 GitHub 上创建 Pull Request，详细描述你的更改。

### Commit 规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型（type）：**

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**示例：**

```bash
feat(request): add support for HTTP/2

Add HTTP/2 support for better performance.

Closes #123
```

```bash
fix(session): fix memory leak in session manager

The session manager was retaining requests after completion.

Fixes #456
```

## 测试

### 编写测试

为新功能添加单元测试：

```swift
import XCTest
@testable import WNNetworkTool

final class YourFeatureTests: XCTestCase {
    
    func testYourFeature() {
        // Given
        let expected = "expected value"
        
        // When
        let actual = yourFunction()
        
        // Then
        XCTAssertEqual(actual, expected)
    }
}
```

### 运行测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter WNNetworkToolTests.testHTTPMethods
```

### 测试覆盖率

我们追求高测试覆盖率（目标 80%+）。

```bash
# 生成测试覆盖率报告
swift test --enable-code-coverage
```

## Pull Request 检查清单

在提交 PR 前，请确认：

- [ ] 代码遵循项目的代码规范
- [ ] 添加了必要的测试
- [ ] 所有测试都通过
- [ ] 更新了相关文档
- [ ] Commit 信息符合规范
- [ ] 代码没有编译警告
- [ ] 没有破坏现有功能

## 报告 Bug

### 提交 Issue 前

1. 搜索现有 Issues，避免重复
2. 确认是否是最新版本的 Bug
3. 准备最小可复现示例

### Bug 报告模板

```markdown
## 描述
简要描述 Bug

## 复现步骤
1. 步骤 1
2. 步骤 2
3. 步骤 3

## 期望行为
描述你期望发生的事情

## 实际行为
描述实际发生的事情

## 环境
- WNNetworkTool 版本: 1.0.0
- Xcode 版本: 14.0
- iOS 版本: 16.0
- 设备: iPhone 14 Pro

## 最小可复现代码
\`\`\`swift
// 你的代码
\`\`\`

## 截图（如适用）
添加截图帮助解释问题
```

## 功能请求

### 提交功能请求

```markdown
## 功能描述
清楚简洁地描述你想要的功能

## 使用场景
描述这个功能的使用场景

## 建议的实现方式
如果有的话，描述你认为应该如何实现

## 替代方案
描述你考虑过的其他替代方案

## 额外信息
其他有助于我们理解需求的信息
```

## 文档贡献

### 改进文档

文档位于以下位置：
- `README.md` - 主要文档
- `QUICKSTART.md` - 快速入门
- `CHANGELOG.md` - 更新日志
- `Examples/` - 示例代码

### 文档风格

- 使用清晰简洁的语言
- 提供代码示例
- 使用 Markdown 格式
- 添加必要的链接

## 版本发布

项目维护者负责版本发布。

### 发布流程

1. 更新 `CHANGELOG.md`
2. 更新版本号
3. 创建 Git Tag
4. 发布到 GitHub Releases

## 行为准则

### 我们的承诺

为了促进开放和友好的环境，我们承诺：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性化的语言或图像
- 人身攻击
- 发布他人的私人信息
- 其他不专业或不受欢迎的行为

## 许可证

通过贡献代码，你同意你的贡献将在 [MIT License](LICENSE) 下授权。

## 问题与联系

如有任何问题，请：

- 📧 发送邮件至 support@example.com
- 💬 在 [Discussions](https://github.com/yourusername/iOS-NetworkTool/discussions) 中提问
- 🐛 在 [Issues](https://github.com/yourusername/iOS-NetworkTool/issues) 中报告问题

---

**感谢你的贡献！** 🙏

