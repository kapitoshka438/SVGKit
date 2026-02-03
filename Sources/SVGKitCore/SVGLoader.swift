import Foundation
import OSLog

/// Actor responsible for loading SVG documents with caching support
/// Thread-safe async loading and caching of SVG documents
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public actor SVGLoader {
    /// Cache storage for loaded documents
    private var cache: [String: CachedDocument] = [:]

    /// Maximum cache size in number of documents
    private let maxCacheSize: Int

    /// Logger for loader operations
    private let logger = SVGLogger.cache

    /// Cached document with metadata
    private struct CachedDocument {
        let data: Data
        let baseURL: URL?
        let loadedAt: Date
        let approximateSize: UInt64
    }

    /// Initialize a new loader
    /// - Parameter maxCacheSize: Maximum number of documents to cache (default: 10)
    public init(maxCacheSize: Int = 10) {
        self.maxCacheSize = maxCacheSize
    }

    /// Load SVG data from a source
    /// - Parameter source: The SVG source
    /// - Returns: Raw SVG data
    /// - Throws: SVGError if loading fails
    public func load(from source: SVGSource) async throws -> Data {
        logger.debug("Loading SVG from source: \(source.cacheKey)")

        // Check cache first
        if let cached = cache[source.cacheKey] {
            logger.debug("Cache hit for: \(source.cacheKey)")
            return cached.data
        }

        // Load data
        let data = try await source.loadDataAsync()
        logger.debug("Loaded \(data.count) bytes from source")

        // Cache it
        let cachedDoc = CachedDocument(
            data: data,
            baseURL: source.baseURL,
            loadedAt: Date(),
            approximateSize: UInt64(data.count)
        )

        cache[source.cacheKey] = cachedDoc

        // Evict oldest if cache is full
        if cache.count > maxCacheSize {
            evictOldest()
        }

        return data
    }

    /// Load SVG data from a named resource
    /// - Parameters:
    ///   - name: Resource name
    ///   - bundle: Bundle to search in (default: main bundle)
    /// - Returns: Raw SVG data
    /// - Throws: SVGError if loading fails
    public func loadCached(named name: String, in bundle: Bundle = .main) async throws -> Data {
        let source = try SVGSource.named(name, in: bundle)
        return try await load(from: source)
    }

    /// Clear the entire cache
    public func clearCache() {
        logger.info("Clearing SVG cache (\(self.cache.count) items)")
        cache.removeAll()
    }

    /// Remove a specific item from cache
    /// - Parameter source: The source to remove from cache
    public func removeCached(source: SVGSource) {
        cache.removeValue(forKey: source.cacheKey)
        logger.debug("Removed from cache: \(source.cacheKey)")
    }

    /// Get cache statistics
    public func cacheStats() -> CacheStatistics {
        let totalSize = cache.values.reduce(0) { $0 + $1.approximateSize }
        return CacheStatistics(
            count: cache.count,
            totalBytes: totalSize,
            maxSize: maxCacheSize
        )
    }

    /// Evict the oldest cached document
    private func evictOldest() {
        guard let oldestKey = cache.min(by: { $0.value.loadedAt < $1.value.loadedAt })?.key else {
            return
        }

        cache.removeValue(forKey: oldestKey)
        logger.debug("Evicted oldest cache entry: \(oldestKey)")
    }
}

// MARK: - Cache Statistics

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct CacheStatistics: Sendable {
    /// Number of cached documents
    public let count: Int

    /// Total size in bytes
    public let totalBytes: UInt64

    /// Maximum cache size
    public let maxSize: Int

    /// Cache utilization percentage
    public var utilization: Double {
        guard maxSize > 0 else { return 0 }
        return Double(count) / Double(maxSize) * 100
    }
}

// MARK: - Shared Instance

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGLoader {
    /// Shared global loader instance
    public static let shared = SVGLoader(maxCacheSize: 20)
}
