import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Circle Cut Renderer

/// Renders the full EditorDocument into a UIImage at the configured resolution.
final class CircleCutRenderer {

    func render(document: EditorDocument) -> UIImage? {
        let settings = document.exportSettings
        let template = document.template

        let canvasW = template.canvasSize.width
        let canvasH = template.canvasSize.height
        let canvasSize = CGSize(width: canvasW, height: canvasH)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // White background
            UIColor.white.setFill()
            cgCtx.fill(CGRect(origin: .zero, size: canvasSize))

            // Compute rects in pixels, accounting for outer border
            let border = template.outerBorderThickness
            let textAreaH = template.textAreaEnabled ? template.textAreaHeight : 0.0
            let textAreaAtTop = template.textAreaPosition == .top
            let imageAreaRect: CGRect
            let textAreaRect: CGRect
            if template.textAreaEnabled {
                if textAreaAtTop {
                    textAreaRect = CGRect(x: border, y: border,
                                          width: canvasW - border * 2, height: textAreaH)
                    imageAreaRect = CGRect(x: border, y: border + textAreaH,
                                           width: canvasW - border * 2, height: canvasH - border * 2 - textAreaH)
                } else if !template.textAreaHasTopBorder {
                    // Text area sits outside the outer border (e.g. Manga Report)
                    imageAreaRect = CGRect(x: border, y: border,
                                           width: canvasW - border * 2, height: canvasH - border * 2 - textAreaH)
                    textAreaRect = CGRect(x: 0, y: canvasH - textAreaH,
                                          width: canvasW, height: textAreaH)
                } else {
                    imageAreaRect = CGRect(x: border, y: border,
                                           width: canvasW - border * 2, height: canvasH - border * 2 - textAreaH)
                    textAreaRect = CGRect(x: border, y: canvasH - border - textAreaH,
                                          width: canvasW - border * 2, height: textAreaH)
                }
            } else {
                imageAreaRect = CGRect(x: border, y: border,
                                       width: canvasW - border * 2, height: canvasH - border * 2)
                textAreaRect = .zero
            }

            // Clip image area (unless bleed)
            if document.bleedOption == .none {
                cgCtx.saveGState()
                cgCtx.clip(to: imageAreaRect)
            }

            // Draw background image
            if let bg = document.backgroundImage, let uiImg = bg.uiImage {
                drawImage(uiImg, in: imageAreaRect, context: cgCtx, element: bg, canvasSize: canvasSize)
            }

            // Draw layers in order
            for layer in document.layers {
                switch layer {
                case .image(let overlay):
                    if let uiImg = overlay.uiImage {
                        drawOverlayImage(uiImg, element: overlay, canvasSize: canvasSize, context: cgCtx)
                    }
                case .text(let textEl):
                    drawTextElement(textEl, canvasSize: canvasSize, context: cgCtx)
                case .shape(let shapeEl):
                    drawShapeElement(shapeEl, canvasSize: canvasSize, context: cgCtx)
                }
            }

            if document.bleedOption == .none {
                cgCtx.restoreGState()
            }

            // Text area background
            if template.textAreaEnabled && !template.textAreaTransparent {
                UIColor.white.setFill()
                cgCtx.fill(textAreaRect)
            }

            // Checkbox area (positioned at inner edge of outer border)
            if template.checkboxAreaEnabled {
                let boxW = template.checkboxAreaSize.width
                let boxH = template.checkboxAreaSize.height
                let boxRect = CGRect(x: border, y: border, width: boxW, height: boxH)
                let innerBorder = template.innerBorderThickness

                UIColor.white.setFill()
                cgCtx.fill(boxRect)

                // Right edge border
                UIColor.black.setFill()
                cgCtx.fill(CGRect(x: border + boxW - innerBorder, y: border,
                                  width: innerBorder, height: boxH))
                // Bottom edge border
                cgCtx.fill(CGRect(x: border, y: border + boxH - innerBorder,
                                  width: boxW, height: innerBorder))
            }

            // Draw main border (inset so it draws entirely inside the canvas)
            let halfBorder = border / 2
            let outerBorderH: CGFloat = {
                if template.textAreaEnabled && !template.textAreaHasTopBorder && !textAreaAtTop {
                    return canvasH - textAreaH
                }
                return canvasH
            }()
            UIColor.black.setStroke()
            cgCtx.setLineWidth(border)
            cgCtx.stroke(CGRect(x: 0, y: 0, width: canvasW, height: outerBorderH)
                .insetBy(dx: halfBorder, dy: halfBorder))

            // Draw text area separator (filled rect to align with box borders)
            if template.textAreaEnabled && template.textAreaHasTopBorder {
                let innerBorder = template.innerBorderThickness
                let dividerY = textAreaAtTop
                    ? border + textAreaH - innerBorder
                    : canvasH - border - textAreaH
                UIColor.black.setFill()
                cgCtx.fill(CGRect(x: 0, y: dividerY, width: canvasW, height: innerBorder))
            }

            // Draw text area's own border (for outside-border text areas like Manga Report)
            if template.textAreaEnabled && !template.textAreaHasTopBorder {
                let halfTA = template.textAreaBorderThickness / 2
                cgCtx.setLineWidth(template.textAreaBorderThickness)
                UIColor.black.setStroke()
                cgCtx.stroke(textAreaRect.insetBy(dx: halfTA, dy: halfTA))
            }

            // Space number (topmost layer)
            if !document.spaceNumber.text.isEmpty {
                let sn = document.spaceNumber
                let innerBorder = template.innerBorderThickness
                // Text content rect excludes the checkbox area and divider border
                let textContentRect: CGRect = {
                    var r = textAreaRect
                    // Exclude divider border
                    if template.textAreaHasTopBorder {
                        if textAreaAtTop {
                            r = CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - innerBorder)
                        } else {
                            r = CGRect(x: r.minX, y: r.minY + innerBorder, width: r.width, height: r.height - innerBorder)
                        }
                    } else if !template.textAreaHasTopBorder && !textAreaAtTop {
                        let tb = template.textAreaBorderThickness
                        r = CGRect(x: r.minX + tb, y: r.minY + tb, width: r.width - tb * 2, height: r.height - tb * 2)
                    }
                    // Exclude checkbox area
                    if textAreaAtTop && template.checkboxAreaEnabled {
                        let boxRight = border + template.checkboxAreaSize.width
                        r = CGRect(x: boxRight, y: r.minY, width: r.maxX - boxRight, height: r.height)
                    }
                    return r
                }()

                switch sn.position {
                case .textArea:
                    if template.textAreaEnabled {
                        drawSpaceNumber(sn, in: textContentRect, context: cgCtx)
                    }
                case .textAreaLeading:
                    if template.textAreaEnabled {
                        let rect = CGRect(x: textContentRect.minX + 8, y: textContentRect.minY,
                                          width: textContentRect.width / 2, height: textContentRect.height)
                        drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .left)
                    }
                case .textAreaTrailing:
                    if template.textAreaEnabled {
                        let rect = CGRect(x: textContentRect.midX, y: textContentRect.minY,
                                          width: textContentRect.width / 2 - 8, height: textContentRect.height)
                        drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .right)
                    }
                case .imageTopLeft:
                    let rect = CGRect(x: imageAreaRect.minX + 8, y: imageAreaRect.minY + 8,
                                      width: imageAreaRect.width / 2, height: 50)
                    drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .left)
                case .imageTopRight:
                    let rect = CGRect(x: imageAreaRect.midX, y: imageAreaRect.minY + 8,
                                      width: imageAreaRect.width / 2 - 8, height: 50)
                    drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .right)
                case .imageBottomLeft:
                    let rect = CGRect(x: imageAreaRect.minX + 8, y: imageAreaRect.maxY - 58,
                                      width: imageAreaRect.width / 2, height: 50)
                    drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .left)
                case .imageBottomRight:
                    let rect = CGRect(x: imageAreaRect.midX, y: imageAreaRect.maxY - 58,
                                      width: imageAreaRect.width / 2 - 8, height: 50)
                    drawSpaceNumber(sn, in: rect, context: cgCtx, alignment: .right)
                }
            }
        }

        guard settings.colorMode == .blackAndWhite else {
            return applyFormat(image, settings: settings)
        }

        guard let bwImage = convertToBlackAndWhite(image) else { return image }
        return applyFormat(bwImage, settings: settings)
    }

    // MARK: - Drawing Helpers

    private func drawImage(_ uiImage: UIImage, in rect: CGRect, context: CGContext, element: ImageElement, canvasSize: CGSize) {
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

    private func drawOverlayImage(_ uiImage: UIImage, element: ImageElement, canvasSize: CGSize, context: CGContext) {
        let centerX = element.position.x * canvasSize.width
        let centerY = element.position.y * canvasSize.height
        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let w = uiImage.size.width / uiImage.size.height * baseSize * element.scale
        let h = baseSize * element.scale

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: element.rotation * .pi / 180)
        uiImage.draw(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        context.restoreGState()
    }

    private func drawTextElement(_ element: TextElement, canvasSize: CGSize, context: CGContext) {
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

    private func drawShapeElement(_ element: ShapeElement, canvasSize: CGSize, context: CGContext) {
        let centerX = element.position.x * canvasSize.width
        let centerY = element.position.y * canvasSize.height
        let w = element.size.width * canvasSize.width * element.scale
        let h = element.size.height * canvasSize.height * element.scale
        let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: element.rotation * .pi / 180)

        let path: CGPath
        switch element.shapeKind {
        case .square, .rectangle:
            path = CGPath(rect: rect, transform: nil)
        case .circle:
            let side = min(w, h)
            path = CGPath(ellipseIn: CGRect(x: -side / 2, y: -side / 2, width: side, height: side), transform: nil)
        case .ellipse:
            path = CGPath(ellipseIn: rect, transform: nil)
        case .triangle:
            path = trianglePath(in: rect)
        case .star:
            path = starPath(in: rect, points: 5)
        case .pentagon:
            path = polygonPath(in: rect, sides: 5)
        case .hexagon:
            path = polygonPath(in: rect, sides: 6)
        }

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

    private func trianglePath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private func starPath(in rect: CGRect, points: Int) -> CGPath {
        let totalPoints = points * 2
        let innerRatio: CGFloat = 0.4

        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for i in 0..<totalPoints {
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
            let radius: CGFloat = i.isMultiple(of: 2) ? 1.0 : innerRatio
            xs.append(cos(angle) * radius)
            ys.append(sin(angle) * radius)
        }

        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = rect.width / (maxX - minX)
        let scaleY = rect.height / (maxY - minY)

        let path = CGMutablePath()
        for i in 0..<totalPoints {
            let point = CGPoint(
                x: rect.minX + (xs[i] - minX) * scaleX,
                y: rect.minY + (ys[i] - minY) * scaleY
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func polygonPath(in rect: CGRect, sides: Int) -> CGPath {
        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for i in 0..<sides {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(sides)) - .pi / 2
            xs.append(cos(angle))
            ys.append(sin(angle))
        }

        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = rect.width / (maxX - minX)
        let scaleY = rect.height / (maxY - minY)

        let path = CGMutablePath()
        for i in 0..<sides {
            let point = CGPoint(
                x: rect.minX + (xs[i] - minX) * scaleX,
                y: rect.minY + (ys[i] - minY) * scaleY
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func drawSpaceNumber(_ info: SpaceNumberInfo, in rect: CGRect, context: CGContext, alignment: NSTextAlignment = .center) {
        let font = UIFont(name: info.fontName, size: info.fontSize) ?? UIFont.boldSystemFont(ofSize: info.fontSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: info.color.uiColor
        ]
        let str = info.text as NSString
        let size = str.size(withAttributes: attrs)
        let x: CGFloat
        switch alignment {
        case .left:
            x = rect.minX
        case .right:
            x = rect.maxX - size.width
        default:
            x = rect.minX + (rect.width - size.width) / 2
        }
        let y = rect.minY + (rect.height - size.height) / 2
        str.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }

    // MARK: - Post Processing

    private func convertToBlackAndWhite(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter.photoEffectMono()
        filter.inputImage = ciImage
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func applyFormat(_ image: UIImage, settings: ExportSettings) -> UIImage {
        if settings.format == .jpg {
            guard let data = image.jpegData(compressionQuality: settings.jpegQuality),
                  let reloaded = UIImage(data: data) else { return image }
            return reloaded
        }
        return image
    }
}
