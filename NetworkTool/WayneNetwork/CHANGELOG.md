# Changelog

All notable changes to WNNetworkTool will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-21

### Added
- Initial release of WNNetworkTool
- HTTP request methods (GET, POST, PUT, DELETE, PATCH, etc.)
- URL and JSON parameter encoding
- Response serialization (Data, String, JSON, Decodable)
- Response validation
- File upload (Data, File, Multipart Form Data)
- File download
- Request/Response interceptors
- Retry policy mechanism
- Network reachability monitoring
- Session management
- Custom headers support
- Request control (cancel, suspend, resume)
- Comprehensive documentation
- Example code for common use cases
- Unit tests

### Core Features

#### Networking
- Asynchronous HTTP requests with completion handlers
- Support for all standard HTTP methods
- Chainable request API
- Custom URLSession configuration

#### Encoding
- URL parameter encoding
- JSON parameter encoding
- Custom parameter encoders
- Multipart form data encoding

#### Response Handling
- Generic response serialization
- Automatic response validation
- JSON response handling
- Decodable type support
- Custom response serializers

#### Advanced Features
- Request adapters for modifying requests
- Request retriers for automatic retry
- Network reachability detection
- Event monitoring
- Request lifecycle management

### Examples
- Basic request examples
- File operation examples
- Network reachability examples
- Advanced usage patterns

### Documentation
- Comprehensive README with usage examples
- API documentation
- Architecture overview
- Migration guide from Alamofire

## [Unreleased]

### Planned Features
- [ ] Request caching
- [ ] Certificate pinning
- [ ] Request prioritization
- [ ] Background uploads/downloads
- [ ] Combine support
- [ ] Async/await support (iOS 15+)
- [ ] Request mocking for testing
- [ ] Better progress tracking
- [ ] Request grouping and cancellation
- [ ] OAuth authentication helper

---

## Version Numbering

WNNetworkTool follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards-compatible manner
- **PATCH** version for backwards-compatible bug fixes

## Release Notes Format

Each release includes:
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

