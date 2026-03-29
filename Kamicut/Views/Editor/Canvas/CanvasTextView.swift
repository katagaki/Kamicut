import SwiftUI

/// Renders text using NSAttributedString as a rendered UIImage, supporting
/// outline, shadow, and plain text — matching the export renderer exactly.
struct CanvasTextView: View {
    let element: TextElement

    var body: some View {
        if let image = renderedImage {
            Image(uiImage: image)
        }
    }

    private var renderedImage: UIImage? {
        let attrs = buildAttributes()
        let str = element.content as NSString
        let size = str.size(withAttributes: attrs)
        guard size.width > 0, size.height > 0 else { return nil }

        // Add padding for shadow overflow
        let padding: CGFloat = element.shadow.enabled
            ? element.shadow.radius * 2 + max(abs(element.shadow.offsetX), abs(element.shadow.offsetY))
            : 0
        let renderSize = CGSize(
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = UITraitCollection.current.displayScale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        return renderer.image { _ in
            str.draw(at: CGPoint(x: padding, y: padding), withAttributes: attrs)
        }
    }

    private func buildAttributes() -> [NSAttributedString.Key: Any] {
        let font = UIFont(name: element.fontName, size: element.fontSize)
            ?? UIFont.systemFont(ofSize: element.fontSize)

        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: element.color.uiColor
        ]

        if element.outline.enabled {
            attrs[.strokeColor] = element.outline.color.uiColor
            attrs[.strokeWidth] = -element.outline.width
        }

        if element.shadow.enabled {
            let shadow = NSShadow()
            shadow.shadowColor = element.shadow.color.uiColor
            shadow.shadowBlurRadius = element.shadow.radius
            shadow.shadowOffset = CGSize(width: element.shadow.offsetX, height: element.shadow.offsetY)
            attrs[.shadow] = shadow
        }

        return attrs
    }
}
