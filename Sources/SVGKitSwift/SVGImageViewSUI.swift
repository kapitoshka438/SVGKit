import SwiftUI
import SVGKitCore
import SVGKitRendering

#if canImport(SwiftUI)

/// SwiftUI view for displaying SVG images
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
public struct SVGImageViewSUI: View {
    let source: SVGSource
    let size: CGSize?

    @State private var image: SVGImage?
    @State private var isLoading = false
    @State private var error: Error?

    /// Initialize with SVG source
    /// - Parameters:
    ///   - source: SVG source
    ///   - size: Optional fixed size (nil = use intrinsic size)
    public init(source: SVGSource, size: CGSize? = nil) {
        self.source = source
        self.size = size
    }

    /// Initialize with named resource
    /// - Parameters:
    ///   - name: Resource name
    ///   - bundle: Bundle (default: main)
    ///   - size: Optional fixed size
    public init(named name: String, bundle: Bundle = .main, size: CGSize? = nil) {
        // Try to get source, fallback to empty string
        self.source = (try? SVGSource.named(name, in: bundle)) ?? .string("", baseURL: nil)
        self.size = size
    }

    /// Initialize with URL
    /// - Parameters:
    ///   - url: File or remote URL
    ///   - size: Optional fixed size
    public init(url: URL, size: CGSize? = nil) {
        if url.isFileURL {
            self.source = .file(url)
        } else {
            self.source = .url(url)
        }
        self.size = size
    }

    public var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error)
            } else if let image = image {
                #if canImport(UIKit)
                SVGImageViewRepresentable(image: image, size: size)
                #elseif canImport(AppKit)
                SVGImageViewRepresentable(image: image, size: size)
                #endif
            } else {
                Color.clear
            }
        }
        .task {
            await loadImage()
        }
    }

    private var loadingView: some View {
        ProgressView()
    }

    private func errorView(_ error: Error) -> some View {
        Text("Failed to load SVG")
            .foregroundColor(.red)
            .font(.caption)
    }

    private func loadImage() async {
        isLoading = true
        error = nil

        do {
            let svgImage = try await SVGImage(source: source)
            self.image = svgImage
        } catch let loadError {
            self.error = loadError
        }

        isLoading = false
    }
}

// MARK: - UIKit Representable

#if canImport(UIKit)
import UIKit

@available(iOS 15.0, tvOS 15.0, *)
struct SVGImageViewRepresentable: UIViewRepresentable {
    let image: SVGImage
    let size: CGSize?

    func makeUIView(context: Context) -> SVGImageView {
        let view = SVGImageView()
        view.image = image
        view.renderingMode = .layered
        return view
    }

    func updateUIView(_ uiView: SVGImageView, context: Context) {
        uiView.image = image
    }
}
#endif

// MARK: - AppKit Representable

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

@available(macOS 12.0, *)
struct SVGImageViewRepresentable: NSViewRepresentable {
    let image: SVGImage
    let size: CGSize?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        Task { @MainActor in
            if let layer = await image.render(size: size, options: RenderOptions()) {
                layer.frame = view.bounds
                view.layer?.addSublayer(layer)
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update if needed
    }
}
#endif

#endif
