import Foundation

extension Bundle {
    static let mypackageResources: Bundle = {
        #if DEBUG
            if let moduleName = Bundle(for: BundleFinder.self).bundleIdentifier,
               let testBundlePath = ProcessInfo.processInfo.environment["XCTestBundlePath"] {
                if let resourceBundle = Bundle(path: testBundlePath + "/\(moduleName)_\(moduleName).bundle") {
                    return resourceBundle
                }
            }
        #endif
        return Bundle.module
    }()

    private final class BundleFinder {}
}
