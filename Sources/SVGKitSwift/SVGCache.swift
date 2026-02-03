import Foundation
import SVGKitCore

/// Thread-safe cache for SVGImage instances
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public actor SVGCache {
    /// Shared cache instance
    public static let shared = SVGCache()

    /// Cached image entry
    private struct CachedEntry {
        let image: SVGImage
        let timestamp: Date
        let size: Int

        init(image: SVGImage, size: Int = 0) {
            self.image = image
            self.timestamp = Date()
            self.size = size
        }
    }

    /// Cache storage
    private var cache: [String: CachedEntry] = [:]

    /// Maximum cache size in bytes (default: 50MB)
    public var maxCacheSize: Int

    /// Maximum age for cached entries in seconds (default: 5 minutes)
    public var maxAge: TimeInterval

    /// Initialize cache
    /// - Parameters:
    ///   - maxSize: Maximum cache size in bytes
    ///   - maxAge: Maximum age for entries
    public init(maxSize: Int = 50 * 1024 * 1024, maxAge: TimeInterval = 300) {
        self.maxCacheSize = maxSize
        self.maxAge = maxAge
    }

    // MARK: - Loading with Cache

    /// Load SVG image with caching
    /// - Parameter source: SVG source
    /// - Returns: Cached or newly loaded SVGImage
    public func image(from source: SVGSource) async throws -> SVGImage {
        let key = source.cacheKey

        // Check cache first
        if let cached = cache[key] {
            // Check if not expired
            if Date().timeIntervalSince(cached.timestamp) < maxAge {
                return cached.image
            } else {
                // Remove expired entry
                cache.removeValue(forKey: key)
            }
        }

        // Load new image
        let image = try await SVGImage(source: source)

        // Estimate size (rough approximation)
        let estimatedSize = estimateSize(for: source)

        // Store in cache
        cache[key] = CachedEntry(image: image, size: estimatedSize)

        // Clean up if needed
        await cleanupIfNeeded()

        return image
    }

    /// Load named resource with caching
    /// - Parameters:
    ///   - name: Resource name
    ///   - bundle: Bundle
    /// - Returns: Cached or newly loaded SVGImage
    public func image(named name: String, in bundle: Bundle = .main) async throws -> SVGImage {
        let source = try SVGSource.named(name, in: bundle)
        return try await image(from: source)
    }

    // MARK: - Cache Management

    /// Store image in cache
    /// - Parameters:
    ///   - image: SVG image to cache
    ///   - key: Cache key
    public func store(_ image: SVGImage, forKey key: String) {
        let estimatedSize = estimateSize(for: image.source)
        cache[key] = CachedEntry(image: image, size: estimatedSize)
        Task {
            await cleanupIfNeeded()
        }
    }

    /// Remove image from cache
    /// - Parameter key: Cache key
    public func removeImage(forKey key: String) {
        cache.removeValue(forKey: key)
    }

    /// Clear entire cache
    public func clearCache() {
        cache.removeAll()
    }

    /// Get cache statistics
    /// - Returns: Tuple of (count, total size in bytes)
    public func statistics() -> (count: Int, totalSize: Int) {
        let count = cache.count
        let totalSize = cache.values.reduce(0) { $0 + $1.size }
        return (count, totalSize)
    }

    // MARK: - Private Helpers

    private func cleanupIfNeeded() async {
        let stats = statistics()

        // Remove expired entries first
        let now = Date()
        cache = cache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < maxAge
        }

        // If still over limit, remove oldest entries
        if stats.totalSize > maxCacheSize {
            let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            var currentSize = stats.totalSize

            for (key, entry) in sorted {
                if currentSize <= maxCacheSize {
                    break
                }
                cache.removeValue(forKey: key)
                currentSize -= entry.size
            }
        }
    }

    private func estimateSize(for source: SVGSource) -> Int {
        // Rough estimate based on source type
        switch source {
        case .data(let data, _):
            return data.count
        case .string(let string, _):
            return string.utf8.count
        case .file, .url:
            return 10_000 // Rough estimate for file-based sources
        }
    }
}
