import Foundation
import QuartzCore
import SVGKitCore
import SVGKitRendering

#if canImport(UIKit)
import UIKit

/// UIKit view for displaying SVG images
@available(iOS 15.0, tvOS 15.0, *)
@MainActor
public final class SVGImageView: UIView {
    /// The SVG image to display
    public var image: SVGImage? {
        didSet {
            if image !== oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Rendering mode
    public var renderingMode: RenderingMode = .layered {
        didSet {
            if renderingMode != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Content mode for SVG rendering
    public var svgContentMode: SVGContentMode = .scaleAspectFit {
        didSet {
            if svgContentMode != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Rendering options
    public var renderOptions: RenderOptions = RenderOptions()

    /// Rendering mode options
    public enum RenderingMode {
        case layered    // Use CALayer (dynamic, animatable)
        case rasterized // Rasterize to UIImage (faster for static content)
    }

    /// Content mode for SVG
    public enum SVGContentMode {
        case scaleAspectFit
        case scaleAspectFill
        case scaleToFill
        case center
    }

    // Private properties
    private var svgLayer: CALayer?
    private var imageView: UIImageView?
    private var renderTask: Task<Void, Never>?

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        renderTask?.cancel()
        renderTask = Task {
            await updateRendering()
        }
    }

    private func updateRendering() async {
        guard let image = image else {
            clearContent()
            return
        }

        let targetSize = calculateTargetSize(for: image)

        switch renderingMode {
        case .layered:
            await renderLayered(image: image, size: targetSize)
        case .rasterized:
            await renderRasterized(image: image, size: targetSize)
        }
    }

    private func renderLayered(image: SVGImage, size: CGSize) async {
        clearImageView()

        guard let layer = await image.render(size: size, options: renderOptions) else {
            return
        }

        // Position layer
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        if let existingLayer = svgLayer {
            existingLayer.removeFromSuperlayer()
        }

        self.layer.addSublayer(layer)
        svgLayer = layer
    }

    private func renderRasterized(image: SVGImage, size: CGSize) async {
        clearSVGLayer()

        guard let rasterized = await image.rasterize(
            size: size,
            scale: UIScreen.main.scale,
            options: renderOptions
        ) else {
            return
        }

        let imageView: UIImageView
        if let existing = self.imageView {
            imageView = existing
        } else {
            imageView = UIImageView(frame: bounds)
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
            self.imageView = imageView
        }

        imageView.image = rasterized
        imageView.frame = bounds
    }

    private func calculateTargetSize(for image: SVGImage) -> CGSize {
        guard let intrinsicSize = image.intrinsicSize else {
            return bounds.size
        }

        switch svgContentMode {
        case .scaleToFill:
            return bounds.size

        case .scaleAspectFit:
            return intrinsicSize.aspectFit(in: bounds.size)

        case .scaleAspectFill:
            return intrinsicSize.aspectFill(in: bounds.size)

        case .center:
            return intrinsicSize
        }
    }

    private func clearContent() {
        clearSVGLayer()
        clearImageView()
    }

    private func clearSVGLayer() {
        svgLayer?.removeFromSuperlayer()
        svgLayer = nil
    }

    private func clearImageView() {
        imageView?.removeFromSuperview()
        imageView = nil
    }

    deinit {
        renderTask?.cancel()
    }
}

// MARK: - CGSize Helpers

private extension CGSize {
    func aspectFit(in targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / width
        let heightRatio = targetSize.height / height
        let ratio = min(widthRatio, heightRatio)
        return CGSize(width: width * ratio, height: height * ratio)
    }

    func aspectFill(in targetSize: CGSize) -> CGSize {
        let widthRatio = targetSize.width / width
        let heightRatio = targetSize.height / height
        let ratio = max(widthRatio, heightRatio)
        return CGSize(width: width * ratio, height: height * ratio)
    }
}

#endif
