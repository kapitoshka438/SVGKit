import XCTest
@testable import SVGKitCore

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGLoaderTests: XCTestCase {

    // MARK: - Initialization

    func testInitialization() {
        let loader = SVGLoader(maxCacheSize: 5)
        XCTAssertNotNil(loader)
    }

    func testSharedInstance() {
        let shared1 = SVGLoader.shared
        let shared2 = SVGLoader.shared

        // Both should reference the same actor
        XCTAssertTrue(shared1 === shared2)
    }

    // MARK: - Loading

    func testLoadFromStringSource() async throws {
        let loader = SVGLoader(maxCacheSize: 5)
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let data = try await loader.load(from: source)

        XCTAssertGreaterThan(data.count, 0)
        let loadedString = String(data: data, encoding: .utf8)
        XCTAssertTrue(loadedString?.contains("<svg") ?? false)
        XCTAssertTrue(loadedString?.contains("<rect") ?? false)
    }

    func testLoadFromDataSource() async throws {
        let loader = SVGLoader(maxCacheSize: 5)
        let svgString = "<svg></svg>"
        let testData = Data(svgString.utf8)

        let source = SVGSource.data(testData, baseURL: nil)
        let data = try await loader.load(from: source)

        XCTAssertEqual(data, testData)
    }

    func testLoadFromFileSource() async throws {
        let loader = SVGLoader(maxCacheSize: 5)

        // Use test SVG file
        let testSVGPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TestSVGs/simple-rect.svg")

        let source = SVGSource.file(testSVGPath)
        let data = try await loader.load(from: source)

        XCTAssertGreaterThan(data.count, 0)
        let loadedString = String(data: data, encoding: .utf8)
        XCTAssertTrue(loadedString?.contains("<svg") ?? false)
    }

    // MARK: - Caching

    func testCaching() async throws {
        let loader = SVGLoader(maxCacheSize: 5)
        let svgString = "<svg>test</svg>"
        let source = SVGSource.string(svgString, baseURL: nil)

        // Load once
        let data1 = try await loader.load(from: source)

        // Load again - should come from cache
        let data2 = try await loader.load(from: source)

        XCTAssertEqual(data1, data2)

        // Check cache stats
        let stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 1)
        XCTAssertGreaterThan(stats.totalBytes, 0)
    }

    func testCacheEviction() async throws {
        let loader = SVGLoader(maxCacheSize: 2)

        // Load 3 items (should evict oldest)
        let source1 = SVGSource.string("<svg>1</svg>", baseURL: nil)
        let source2 = SVGSource.string("<svg>2</svg>", baseURL: nil)
        let source3 = SVGSource.string("<svg>3</svg>", baseURL: nil)

        _ = try await loader.load(from: source1)
        _ = try await loader.load(from: source2)
        _ = try await loader.load(from: source3)

        let stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 2, "Cache should only contain 2 items after eviction")
    }

    func testClearCache() async throws {
        let loader = SVGLoader(maxCacheSize: 5)
        let source = SVGSource.string("<svg>test</svg>", baseURL: nil)

        _ = try await loader.load(from: source)

        var stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 1)

        await loader.clearCache()

        stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 0)
    }

    func testRemoveCached() async throws {
        let loader = SVGLoader(maxCacheSize: 5)
        let source1 = SVGSource.string("<svg>1</svg>", baseURL: nil)
        let source2 = SVGSource.string("<svg>2</svg>", baseURL: nil)

        _ = try await loader.load(from: source1)
        _ = try await loader.load(from: source2)

        var stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 2)

        await loader.removeCached(source: source1)

        stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 1)
    }

    // MARK: - Cache Statistics

    func testCacheStatistics() async throws {
        let loader = SVGLoader(maxCacheSize: 10)
        let source1 = SVGSource.string("<svg>short</svg>", baseURL: nil)
        let source2 = SVGSource.string("<svg>longer content here</svg>", baseURL: nil)

        _ = try await loader.load(from: source1)
        _ = try await loader.load(from: source2)

        let stats = await loader.cacheStats()

        XCTAssertEqual(stats.count, 2)
        XCTAssertGreaterThan(stats.totalBytes, 0)
        XCTAssertEqual(stats.maxSize, 10)
        XCTAssertEqual(stats.utilization, 20.0, accuracy: 0.1) // 2/10 = 20%
    }

    func testCacheUtilization() async throws {
        let loader = SVGLoader(maxCacheSize: 5)

        // Load 3 items
        for i in 1...3 {
            let source = SVGSource.string("<svg>\(i)</svg>", baseURL: nil)
            _ = try await loader.load(from: source)
        }

        let stats = await loader.cacheStats()
        XCTAssertEqual(stats.utilization, 60.0, accuracy: 0.1) // 3/5 = 60%
    }

    // MARK: - Named Resource Loading

    func testLoadNamedResourceNotFound() async {
        let loader = SVGLoader(maxCacheSize: 5)

        do {
            _ = try await loader.loadCached(named: "nonexistent-\(UUID())")
            XCTFail("Should have thrown an error")
        } catch let error as SVGError {
            if case .fileNotFound = error {
                // Expected
            } else {
                XCTFail("Expected fileNotFound error, got: \(error)")
            }
        } catch {
            XCTFail("Expected SVGError, got: \(error)")
        }
    }

    // MARK: - Concurrent Loading

    func testConcurrentLoading() async throws {
        let loader = SVGLoader(maxCacheSize: 10)

        // Load multiple sources concurrently
        let sources = (1...5).map { SVGSource.string("<svg>\($0)</svg>", baseURL: nil) }

        await withTaskGroup(of: Result<Data, Error>.self) { group in
            for source in sources {
                group.addTask {
                    do {
                        let data = try await loader.load(from: source)
                        return .success(data)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var successCount = 0
            for await result in group {
                if case .success = result {
                    successCount += 1
                }
            }

            XCTAssertEqual(successCount, 5)
        }

        let stats = await loader.cacheStats()
        XCTAssertEqual(stats.count, 5)
    }

    // MARK: - Error Handling

    func testLoadingNonExistentFile() async {
        let loader = SVGLoader(maxCacheSize: 5)
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID()).svg")
        let source = SVGSource.file(url)

        do {
            _ = try await loader.load(from: source)
            XCTFail("Should have thrown an error")
        } catch let error as SVGError {
            if case .cannotReadFile = error {
                // Expected
            } else {
                XCTFail("Expected cannotReadFile error, got: \(error)")
            }
        } catch {
            XCTFail("Expected SVGError, got: \(error)")
        }
    }

    // MARK: - Performance

    func testLoadingPerformance() async throws {
        let loader = SVGLoader(maxCacheSize: 20)
        let svgString = String(repeating: "<rect x=\"0\" y=\"0\" width=\"10\" height=\"10\" />", count: 100)
        let fullSVG = "<svg>\(svgString)</svg>"
        let source = SVGSource.string(fullSVG, baseURL: nil)

        measure {
            let expectation = self.expectation(description: "Loading")

            Task {
                _ = try await loader.load(from: source)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testCachePerformance() async throws {
        let loader = SVGLoader(maxCacheSize: 20)
        let source = SVGSource.string("<svg>test</svg>", baseURL: nil)

        // Pre-load to cache
        _ = try await loader.load(from: source)

        measure {
            let expectation = self.expectation(description: "Cache loading")

            Task {
                _ = try await loader.load(from: source)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }
}
