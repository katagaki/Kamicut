import UIKit

// MARK: - Drawing Helpers

extension CircleCutRenderer {

    func drawImage(_ uiImage: UIImage, in rect: CGRect, context: CGContext, element: ImageElement, canvasSize: CGSize) {
        let imgSize = uiImage.size
        let scale = max(rect.width / imgSize.width, rect.height / imgSize.height)
        let scaledW = imgSize.width * scale
        let scaledH = imgSize.height * scale
        let drawRect = CGRect(
            x: rect.minX + (rect.width - scaledW) / 2,
            y: rect.minY + (rect.height - scaledH) / 2,
            width: scaledW,
            height: scaledH
        )
        uiImage.draw(in: drawRect)
    }

    func drawOverlayImage(_ uiImage: UIImage, element: ImageElement, canvasSize: CGSize, context: CGContext) {
        let centerX = element.position.x * canvasSize.width
        let centerY = element.position.y * canvasSize.height
        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let width = uiImage.size.width / uiImage.size.height * baseSize * element.scale
        let height = baseSize * element.scale

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: element.rotation * .pi / 180)

        if element.shadow.enabled {
            context.setShadow(
                offset: CGSize(width: element.shadow.offsetX, height: element.shadow.offsetY),
                blur: element.shadow.radius,
                color: element.shadow.color.uiColor.cgColor
            )
        }

        uiImage.draw(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        context.restoreGState()
    }

    func drawTextElement(_ element: TextElement, canvasSize: CGSize, context: CGContext) {
        let centerX = element.position.x * canvasSize.width
        let centerY = element.position.y * canvasSize.height
        let font = UIFont(name: element.fontName, size: element.fontSize) ?? UIFont.systemFont(ofSize: element.fontSize)

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: element.rotation * .pi / 180)

        let attrs = buildTextAttributes(element: element, font: font)
        let str = element.content as NSString
        let size = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: -size.width / 2, y: -size.height / 2), withAttributes: attrs)

        context.restoreGState()
    }

    func drawShapeElement(_ element: ShapeElement, canvasSize: CGSize, context: CGContext) {
        let centerX = element.position.x * canvasSize.width
        let centerY = element.position.y * canvasSize.height
        let width = element.size.width * canvasSize.width * element.scale
        let height = element.size.height * canvasSize.height * element.scale
        let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: element.rotation * .pi / 180)

        let path = shapePath(for: element.shapeKind, in: rect, width: width, height: height)

        context.addPath(path)
        context.setFillColor(element.fillColor.uiColor.cgColor)
        context.fillPath()

        if element.strokeWidth > 0 {
            context.addPath(path)
            context.setStrokeColor(element.strokeColor.uiColor.cgColor)
            context.setLineWidth(element.strokeWidth)
            context.strokePath()
        }

        context.restoreGState()
    }

    // MARK: - Private Helpers

    private func buildTextAttributes(element: TextElement, font: UIFont) -> [NSAttributedString.Key: Any] {
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

    private func shapePath(for kind: ShapeKind, in rect: CGRect, width: CGFloat, height: CGFloat) -> CGPath {
        switch kind {
        case .square, .rectangle:
            return CGPath(rect: rect, transform: nil)
        case .circle:
            let side = min(width, height)
            return CGPath(ellipseIn: CGRect(x: -side / 2, y: -side / 2, width: side, height: side), transform: nil)
        case .ellipse:
            return CGPath(ellipseIn: rect, transform: nil)
        case .triangle:
            return trianglePath(in: rect)
        case .star:
            return starPath(in: rect, points: 5)
        case .pentagon:
            return polygonPath(in: rect, sides: 5)
        case .hexagon:
            return polygonPath(in: rect, sides: 6)
        }
    }
}
