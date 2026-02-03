import Foundation

/// Represents the source of SVG data
/// Modern Swift replacement for Objective-C SVGKSource class hierarchy
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum SVGSource: Sendable, Hashable {
    /// SVG data from a local file URL
    case file(URL)

    /// SVG data from a remote URL
    case url(URL)

    /// SVG data from raw Data
    case data(Data, baseURL: URL?)

    /// SVG data from a String
    case string(String, baseURL: URL?)

    /// The base URL for resolving relative references (images, links, etc.)
    public var baseURL: URL? {
        switch self {
        case .file(let url):
            return url.deletingLastPathComponent()
        case .url(let url):
            return url.deletingLastPathComponent()
        case .data(_, let baseURL):
            return baseURL
        case .string(_, let baseURL):
            return baseURL
        }
    }

    /// A key that can be used for caching
    public var cacheKey: String {
        switch self {
        case .file(let url):
            return "file:\(url.path)"
        case .url(let url):
            return "url:\(url.absoluteString)"
        case .data(let data, let baseURL):
            let dataHash = data.hashValue
            let baseString = baseURL?.absoluteString ?? "none"
            return "data:\(dataHash):base:\(baseString)"
        case .string(let string, let baseURL):
            let stringHash = string.hashValue
            let baseString = baseURL?.absoluteString ?? "none"
            return "string:\(stringHash):base:\(baseString)"
        }
    }

    /// Approximate length in bytes (if known)
    public var approximateLengthInBytes: UInt64? {
        switch self {
        case .file(let url):
            return try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64
        case .url:
            return nil // Unknown until downloaded
        case .data(let data, _):
            return UInt64(data.count)
        case .string(let string, _):
            return UInt64(string.utf8.count)
        }
    }
}

// MARK: - Data Access

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGSource {
    /// Load the SVG data synchronously
    /// - Throws: SVGError if data cannot be loaded
    /// - Returns: The SVG data as Data
    public func loadData() throws -> Data {
        switch self {
        case .file(let url):
            do {
                return try Data(contentsOf: url)
            } catch {
                throw SVGError.cannotReadFile(url, underlyingError: error)
            }

        case .url(let url):
            // For synchronous loading, we need to use URLSession synchronously
            // This is not ideal but matches the Obj-C behavior
            var data: Data?
            var error: Error?
            let semaphore = DispatchSemaphore(value: 0)

            URLSession.shared.dataTask(with: url) { responseData, _, taskError in
                data = responseData
                error = taskError
                semaphore.signal()
            }.resume()

            semaphore.wait()

            if let error = error {
                throw SVGError.networkError(url, underlyingError: error)
            }

            guard let data = data else {
                throw SVGError.networkError(url, underlyingError: nil)
            }

            return data

        case .data(let data, _):
            return data

        case .string(let string, _):
            guard let data = string.data(using: .utf8) else {
                throw SVGError.cannotReadData("Cannot convert string to UTF-8 data")
            }
            return data
        }
    }

    /// Load the SVG data asynchronously
    /// - Returns: The SVG data as Data
    /// - Throws: SVGError if data cannot be loaded
    public func loadDataAsync() async throws -> Data {
        switch self {
        case .file(let url):
            do {
                return try Data(contentsOf: url)
            } catch {
                throw SVGError.cannotReadFile(url, underlyingError: error)
            }

        case .url(let url):
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return data
            } catch {
                throw SVGError.networkError(url, underlyingError: error)
            }

        case .data(let data, _):
            return data

        case .string(let string, _):
            guard let data = string.data(using: .utf8) else {
                throw SVGError.cannotReadData("Cannot convert string to UTF-8 data")
            }
            return data
        }
    }

    /// Create an InputStream for the SVG data
    /// Used for compatibility with existing parsing code
    public func createInputStream() throws -> InputStream {
        let data = try loadData()
        return InputStream(data: data)
    }
}

// MARK: - Convenience Initializers

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGSource {
    /// Create a source from a file path
    public static func file(path: String) throws -> SVGSource {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SVGError.fileNotFound(url)
        }
        return .file(url)
    }

    /// Create a source from a named resource in a bundle
    public static func named(_ name: String, in bundle: Bundle = .main) throws -> SVGSource {
        // Try with .svg extension first
        if let url = bundle.url(forResource: name, withExtension: "svg") {
            return .file(url)
        }

        // Try without extension (maybe name already includes .svg)
        if let url = bundle.url(forResource: name, withExtension: nil) {
            return .file(url)
        }

        // Try to find any SVG file matching the name
        if let url = bundle.url(forResource: name, withExtension: "SVG") {
            return .file(url)
        }

        throw SVGError.fileNotFound(URL(fileURLWithPath: name))
    }

    /// Create a source from a URL string
    public static func url(string: String) throws -> SVGSource {
        guard let url = URL(string: string) else {
            throw SVGError.invalidURL(string)
        }
        return .url(url)
    }
}

// MARK: - Relative Path Resolution

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGSource {
    /// Create a new source from a relative path
    /// Used for resolving referenced resources (images, use elements, etc.)
    public func sourceFromRelativePath(_ relativePath: String) throws -> SVGSource {
        guard let baseURL = self.baseURL else {
            throw SVGError.invalidSource("Cannot resolve relative path without base URL")
        }

        let resolvedURL = baseURL.appendingPathComponent(relativePath)

        // Check if it's a file URL or remote URL
        if resolvedURL.isFileURL {
            return .file(resolvedURL)
        } else {
            return .url(resolvedURL)
        }
    }
}
