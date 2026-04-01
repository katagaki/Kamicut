import UIKit

// MARK: - Circle Cut Renderer

/// Renders the full EditorDocument into a UIImage at the configured resolution.
final class CircleCutRenderer {

    func render(document: EditorDocument) -> UIImage? {
        let settings = document.exportSettings
        let template = document.template

        let canvasSize = template.canvasSize
        let image = renderCanvas(document: document, template: template, canvasSize: canvasSize)

        guard settings.colorMode == .blackAndWhite else {
            return applyFormat(image, settings: settings)
        }

        guard let bwImage = convertToBlackAndWhite(image) else { return image }
        return applyFormat(bwImage, settings: settings)
    }

    // MARK: - Canvas Rendering

    private func renderCanvas(document: EditorDocument, template: CircleCutTemplate, canvasSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let layout = CanvasLayout(template: template, canvasSize: canvasSize)

            drawBackground(document: document, context: cgCtx, canvasSize: canvasSize)
            drawImageArea(document: document, layout: layout, canvasSize: canvasSize, context: cgCtx)
            drawTextAreaBackground(template: template, layout: layout, context: cgCtx)
            drawCheckboxArea(template: template, layout: layout, context: cgCtx)
            drawBorders(template: template, layout: layout, canvasSize: canvasSize, context: cgCtx)
            drawSpaceNumberOverlay(document: document, template: template, layout: layout, context: cgCtx)
        }
    }

    // MARK: - Layout

    struct CanvasLayout {
        let imageAreaRect: CGRect
        let textAreaRect: CGRect
        let textAreaH: CGFloat
        let textAreaAtTop: Bool

        init(template: CircleCutTemplate, canvasSize: CGSize) {
            let canvasW = canvasSize.width
            let canvasH = canvasSize.height
            let border = template.outerBorderThickness
            textAreaH = template.textAreaEnabled ? template.textAreaHeight : 0.0
            textAreaAtTop = template.textAreaPosition == .top

            if template.textAreaEnabled {
                if textAreaAtTop {
                    textAreaRect = CGRect(x: border, y: border,
                                          width: canvasW - border * 2, height: textAreaH)
                    imageAreaRect = CGRect(x: border, y: border + textAreaH,
                                           width: canvasW - border * 2, height: canvasH - border * 2 - textAreaH)
                } else if !template.textAreaHasTopBorder {
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
        }
    }

    // MARK: - Render Sub-steps

    private func drawBackground(document: EditorDocument, context: CGContext, canvasSize: CGSize) {
        let color = document.backgroundColor?.uiColor ?? UIColor.white
        color.setFill()
        context.fill(CGRect(origin: .zero, size: canvasSize))
    }

    private func drawImageArea(document: EditorDocument, layout: CanvasLayout, canvasSize: CGSize, context: CGContext) {
        let template = document.template
        let transparentTextArea = template.textAreaEnabled && template.textAreaTransparent

        // Draw background image clipped to imageAreaRect only
        if let background = document.backgroundImage, let uiImg = background.uiImage {
            context.saveGState()
            if document.bleedOption == .none {
                context.clip(to: layout.imageAreaRect)
            }
            let bgRect = document.bleedOption == .full
                ? CGRect(origin: .zero, size: canvasSize)
                : layout.imageAreaRect
            drawImage(uiImg, in: bgRect, context: context, element: background, canvasSize: canvasSize)
            context.restoreGState()
        }

        // Draw layers clipped to imageAreaRect + textAreaRect when transparent
        if document.bleedOption == .none {
            context.saveGState()
            if transparentTextArea {
                let path = CGMutablePath()
                path.addRect(layout.imageAreaRect)
                path.addRect(layout.textAreaRect)
                context.addPath(path)
                context.clip(using: .winding)
            } else {
                context.clip(to: layout.imageAreaRect)
            }
        }

        for layer in document.layers {
            switch layer {
            case .image(let overlay):
                if let uiImg = overlay.uiImage {
                    drawOverlayImage(uiImg, element: overlay, canvasSize: canvasSize, context: context)
                }
            case .text(let textEl):
                drawTextElement(textEl, canvasSize: canvasSize, context: context)
            case .shape(let shapeEl):
                drawShapeElement(shapeEl, canvasSize: canvasSize, context: context)
            }
        }

        if document.bleedOption == .none {
            context.restoreGState()
        }
    }

    private func drawTextAreaBackground(template: CircleCutTemplate, layout: CanvasLayout, context: CGContext) {
        guard template.textAreaEnabled, !template.textAreaTransparent else { return }
        UIColor.white.setFill()
        context.fill(layout.textAreaRect)
    }

    private func drawCheckboxArea(template: CircleCutTemplate, layout: CanvasLayout, context: CGContext) {
        guard template.checkboxAreaEnabled else { return }
        let border = template.outerBorderThickness
        let boxW = template.checkboxAreaSize.width
        let boxH = template.checkboxAreaSize.height
        let boxRect = CGRect(x: border, y: border, width: boxW, height: boxH)
        let innerBorder = template.innerBorderThickness

        UIColor.white.setFill()
        context.fill(boxRect)

        template.innerBorderColor.uiColor.setFill()
        context.fill(CGRect(x: border + boxW - innerBorder, y: border,
                            width: innerBorder, height: boxH))
        context.fill(CGRect(x: border, y: border + boxH - innerBorder,
                            width: boxW, height: innerBorder))
    }

    private func drawBorders(
        template: CircleCutTemplate, layout: CanvasLayout, canvasSize: CGSize, context: CGContext
    ) {
        let border = template.outerBorderThickness
        let halfBorder = border / 2

        let outerBorderH: CGFloat
        if template.textAreaEnabled && !template.textAreaHasTopBorder && !layout.textAreaAtTop {
            outerBorderH = canvasSize.height - layout.textAreaH
        } else {
            outerBorderH = canvasSize.height
        }

        template.outerBorderColor.uiColor.setStroke()
        context.setLineWidth(border)
        context.stroke(CGRect(x: 0, y: 0, width: canvasSize.width, height: outerBorderH)
            .insetBy(dx: halfBorder, dy: halfBorder))

        if template.textAreaEnabled && template.textAreaHasTopBorder {
            let innerBorder = template.innerBorderThickness
            let dividerY = layout.textAreaAtTop
                ? border + layout.textAreaH - innerBorder
                : canvasSize.height - border - layout.textAreaH
            template.innerBorderColor.uiColor.setFill()
            context.fill(CGRect(x: border, y: dividerY, width: canvasSize.width - border * 2, height: innerBorder))
        }

        if template.textAreaEnabled && !template.textAreaHasTopBorder {
            let halfTA = template.textAreaBorderThickness / 2
            context.setLineWidth(template.textAreaBorderThickness)
            template.innerBorderColor.uiColor.setStroke()
            context.stroke(layout.textAreaRect.insetBy(dx: halfTA, dy: halfTA))
        }
    }

    private func drawSpaceNumberOverlay(
        document: EditorDocument, template: CircleCutTemplate, layout: CanvasLayout, context: CGContext
    ) {
        guard !document.spaceNumber.text.isEmpty else { return }
        let spaceNum = document.spaceNumber
        let textContentRect = computeTextContentRect(template: template, layout: layout)

        drawSpaceNumberForPosition(
            spaceNum,
            template: template,
            layout: layout,
            textContentRect: textContentRect,
            context: context
        )
    }

    private func computeTextContentRect(template: CircleCutTemplate, layout: CanvasLayout) -> CGRect {
        let border = template.outerBorderThickness
        let innerBorder = template.innerBorderThickness
        var rect = layout.textAreaRect

        if template.textAreaHasTopBorder {
            if layout.textAreaAtTop {
                rect = CGRect(x: rect.minX, y: rect.minY,
                              width: rect.width, height: rect.height - innerBorder)
            } else {
                rect = CGRect(x: rect.minX, y: rect.minY + innerBorder,
                              width: rect.width, height: rect.height - innerBorder)
            }
        } else if !layout.textAreaAtTop {
            let borderThickness = template.textAreaBorderThickness
            rect = CGRect(x: rect.minX + borderThickness, y: rect.minY + borderThickness,
                          width: rect.width - borderThickness * 2, height: rect.height - borderThickness * 2)
        }

        if layout.textAreaAtTop && template.checkboxAreaEnabled {
            let boxRight = border + template.checkboxAreaSize.width
            rect = CGRect(x: boxRight, y: rect.minY, width: rect.maxX - boxRight, height: rect.height)
        }

        return rect
    }

    private func drawSpaceNumberForPosition(
        _ spaceNum: SpaceNumberInfo,
        template: CircleCutTemplate,
        layout: CanvasLayout,
        textContentRect: CGRect,
        context: CGContext
    ) {
        switch spaceNum.position {
        case .textArea:
            guard template.textAreaEnabled else { return }
            drawSpaceNumber(spaceNum, in: textContentRect, context: context)
        case .textAreaLeading:
            guard template.textAreaEnabled else { return }
            let rect = CGRect(x: textContentRect.minX + 8, y: textContentRect.minY,
                              width: textContentRect.width / 2, height: textContentRect.height)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .left)
        case .textAreaTrailing:
            guard template.textAreaEnabled else { return }
            let rect = CGRect(x: textContentRect.midX, y: textContentRect.minY,
                              width: textContentRect.width / 2 - 8, height: textContentRect.height)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .right)
        case .imageTopLeft:
            let rect = CGRect(x: layout.imageAreaRect.minX + 8, y: layout.imageAreaRect.minY + 8,
                              width: layout.imageAreaRect.width / 2, height: 50)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .left)
        case .imageTopRight:
            let rect = CGRect(x: layout.imageAreaRect.midX, y: layout.imageAreaRect.minY + 8,
                              width: layout.imageAreaRect.width / 2 - 8, height: 50)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .right)
        case .imageBottomLeft:
            let rect = CGRect(x: layout.imageAreaRect.minX + 8, y: layout.imageAreaRect.maxY - 58,
                              width: layout.imageAreaRect.width / 2, height: 50)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .left)
        case .imageBottomRight:
            let rect = CGRect(x: layout.imageAreaRect.midX, y: layout.imageAreaRect.maxY - 58,
                              width: layout.imageAreaRect.width / 2 - 8, height: 50)
            drawSpaceNumber(spaceNum, in: rect, context: context, alignment: .right)
        }
    }
}
