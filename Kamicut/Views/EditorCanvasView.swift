import SwiftUI

// MARK: - Editor Canvas View

struct EditorCanvasView: View {
    @Bindable var vm: EditorState

    private var canvasSize: CGSize { vm.document.template.canvasSize }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Canvas background
            canvasBackground

            // Background image (image area only, unless bleed)
            if let bg = vm.document.backgroundImage, let uiImg = bg.uiImage {
                backgroundImageLayer(uiImg)
            }

            // Layers (images and text in unified z-order)
            ForEach(Array(vm.document.layers.enumerated()), id: \.element.id) { index, layer in
                switch layer {
                case .image(let imageEl):
                    OverlayImageView(
                        element: Binding(
                            get: {
                                if case .image(let el) = vm.document.layers[safe: index] { return el }
                                return imageEl
                            },
                            set: { vm.document.layers[index] = .image($0) }
                        ),
                        canvasSize: canvasSize,
                        isSelected: vm.selectedImageID == imageEl.id,
                        onTap: { vm.selectLayer(id: imageEl.id) }
                    )
                case .text(let textEl):
                    TextElementView(
                        element: Binding(
                            get: {
                                if case .text(let el) = vm.document.layers[safe: index] { return el }
                                return textEl
                            },
                            set: { vm.document.layers[index] = .text($0) }
                        ),
                        canvasSize: canvasSize,
                        isSelected: vm.selectedTextID == textEl.id,
                        onTap: { vm.selectLayer(id: textEl.id) }
                    )
                }
            }

            // Text area
            textAreaOverlay

            // Top-left box
            topLeftBoxOverlay

            // Border
            canvasBorder

            // Space number (topmost layer)
            spaceNumberOverlay
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectedImageID = nil
            vm.selectedTextID = nil
        }
    }

    // MARK: - Subviews

    private var canvasBackground: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func backgroundImageLayer(_ uiImg: UIImage) -> some View {
        let template = vm.document.template
        let border = template.outerBorderThickness
        let imgAreaH = imageAreaHeight
        let imageAreaY: CGFloat
        if vm.bleedOption == .full {
            imageAreaY = 0
        } else if template.textAreaEnabled && template.textAreaPosition == .top {
            imageAreaY = border + template.textAreaHeight
        } else {
            imageAreaY = border
        }
        return Image(uiImage: uiImg)
            .resizable()
            .scaledToFill()
            .frame(
                width: vm.bleedOption == .full ? canvasSize.width : canvasSize.width - border * 2,
                height: vm.bleedOption == .full ? canvasSize.height : imgAreaH
            )
            .clipped()
            .offset(x: vm.bleedOption == .full ? 0 : border, y: imageAreaY)
            .allowsHitTesting(false)
    }

    private var textAreaOverlay: some View {
        let template = vm.document.template
        guard template.textAreaEnabled else { return AnyView(EmptyView()) }
        let border = template.outerBorderThickness
        let textH = template.textAreaHeight
        let textY: CGFloat
        let textX: CGFloat
        let textW: CGFloat
        if template.textAreaPosition == .top {
            textY = border
            if template.topLeftBoxEnabled {
                let boxTotalW = border + template.topLeftBoxSize.width
                textX = boxTotalW
                textW = canvasSize.width - boxTotalW - border
            } else {
                textX = border
                textW = canvasSize.width - border * 2
            }
        } else if !template.textAreaHasTopBorder {
            // Text area sits outside the outer border (e.g. Manga Report)
            textY = canvasSize.height - textH
            textX = 0
            textW = canvasSize.width
        } else {
            textY = canvasSize.height - border - textH
            textX = border
            textW = canvasSize.width - border * 2
        }
        return AnyView(
            ZStack(alignment: .center) {
                if !template.textAreaTransparent {
                    Rectangle()
                        .fill(Color.white)
                }
                // Text area own border (when it has its own border style)
                if !template.textAreaHasTopBorder && template.textAreaPosition == .bottom {
                    Rectangle()
                        .strokeBorder(Color.black, lineWidth: template.textAreaBorderThickness)
                }
            }
            .frame(width: textW, height: textH)
            .offset(x: textX, y: textY)
        )
    }

    private var topLeftBoxOverlay: some View {
        let template = vm.document.template
        guard template.topLeftBoxEnabled else { return AnyView(EmptyView()) }
        let border = template.outerBorderThickness
        let innerBorder = template.innerBorderThickness
        let boxW = template.topLeftBoxSize.width
        let boxH = template.topLeftBoxSize.height
        return AnyView(
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.white)
                // Right edge border
                Rectangle()
                    .fill(Color.black)
                    .frame(width: innerBorder, height: boxH)
                    .offset(x: boxW - innerBorder)
                // Bottom edge border
                Rectangle()
                    .fill(Color.black)
                    .frame(width: boxW, height: innerBorder)
                    .offset(y: boxH - innerBorder)
            }
            .frame(width: boxW, height: boxH)
            .offset(x: border, y: border)
        )
    }

    private var spaceNumberOverlay: some View {
        let template = vm.document.template
        let sn = vm.spaceNumber
        guard !sn.text.isEmpty else { return AnyView(EmptyView()) }

        let font = Font.custom(sn.fontName, size: sn.fontSize)
        let color = sn.color.color

        switch sn.position {
        case .topLeftBox:
            guard template.topLeftBoxEnabled else { return AnyView(EmptyView()) }
            let border = template.outerBorderThickness
            let innerBorder = template.innerBorderThickness
            // Content area is box size minus right and bottom inner borders
            let contentW = template.topLeftBoxSize.width - innerBorder
            let contentH = template.topLeftBoxSize.height - innerBorder
            return AnyView(
                Text(sn.text)
                    .font(font)
                    .foregroundColor(color)
                    .minimumScaleFactor(0.3)
                    .lineLimit(2)
                    .frame(width: contentW, height: contentH)
                    .offset(x: border, y: border)
                    .allowsHitTesting(false)
            )

        case .textArea:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let r = textAreaContentRect
            return AnyView(
                Text(sn.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(width: r.width, height: r.height)
                    .offset(x: r.minX, y: r.minY)
                    .allowsHitTesting(false)
            )

        case .textAreaLeading:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let r = textAreaContentRect
            return AnyView(
                Text(sn.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .padding(.leading, 8)
                    .frame(width: r.width, height: r.height, alignment: .leading)
                    .offset(x: r.minX, y: r.minY)
                    .allowsHitTesting(false)
            )

        case .textAreaTrailing:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let r = textAreaContentRect
            return AnyView(
                Text(sn.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .padding(.trailing, 8)
                    .frame(width: r.width, height: r.height, alignment: .trailing)
                    .offset(x: r.minX, y: r.minY)
                    .allowsHitTesting(false)
            )

        case .imageTopLeft, .imageTopRight, .imageBottomLeft, .imageBottomRight:
            let border = template.outerBorderThickness
            let imgAreaH = imageAreaHeight
            let imageAreaY: CGFloat = (template.textAreaEnabled && template.textAreaPosition == .top)
                ? border + template.textAreaHeight : border
            let alignment: Alignment = {
                switch sn.position {
                case .imageTopLeft: return .topLeading
                case .imageTopRight: return .topTrailing
                case .imageBottomLeft: return .bottomLeading
                case .imageBottomRight: return .bottomTrailing
                default: return .center
                }
            }()
            return AnyView(
                Text(sn.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .padding(8)
                    .frame(width: canvasSize.width - border * 2, height: imgAreaH, alignment: alignment)
                    .offset(x: border, y: imageAreaY)
                    .allowsHitTesting(false)
            )
        }
    }

    private var canvasBorder: some View {
        let template = vm.document.template
        let border = template.outerBorderThickness
        // When text area is outside the border (no top border, bottom position),
        // the outer border only covers the area above the text area
        let outerBorderHeight: CGFloat = {
            if template.textAreaEnabled && !template.textAreaHasTopBorder && template.textAreaPosition == .bottom {
                return canvasSize.height - template.textAreaHeight
            }
            return canvasSize.height
        }()
        return ZStack(alignment: .topLeading) {
            // Outer border (inset so it draws entirely inside the canvas)
            Rectangle()
                .strokeBorder(Color.black, lineWidth: border)
                .frame(width: canvasSize.width, height: outerBorderHeight)
            // Text area divider (filled rect to align with box borders)
            if template.textAreaEnabled && template.textAreaHasTopBorder {
                let textH = template.textAreaHeight
                let innerBorder = template.innerBorderThickness
                let dividerY = template.textAreaPosition == .top
                    ? border + textH - innerBorder
                    : canvasSize.height - border - textH
                Rectangle()
                    .fill(Color.black)
                    .frame(width: canvasSize.width, height: innerBorder)
                    .offset(y: dividerY)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Geometry Helpers

    private var imageAreaHeight: CGFloat {
        let t = vm.document.template
        let border = t.outerBorderThickness
        if t.textAreaEnabled && !t.textAreaHasTopBorder && t.textAreaPosition == .bottom {
            // Text area is outside the outer border
            return canvasSize.height - t.textAreaHeight - border * 2
        }
        let textH = t.textAreaEnabled ? t.textAreaHeight : 0
        return canvasSize.height - border * 2 - textH
    }

    /// The text area rect, positioned after the outer border and to the right of the top-left box when at top.
    private var textAreaRect: CGRect {
        let t = vm.document.template
        let border = t.outerBorderThickness
        let textH = t.textAreaHeight
        if t.textAreaPosition == .top {
            let textY = border
            if t.topLeftBoxEnabled {
                let boxTotalW = border + t.topLeftBoxSize.width
                return CGRect(x: boxTotalW, y: textY, width: canvasSize.width - boxTotalW - border, height: textH)
            }
            return CGRect(x: border, y: textY, width: canvasSize.width - border * 2, height: textH)
        } else if !t.textAreaHasTopBorder {
            // Text area outside the outer border
            let textY = canvasSize.height - textH
            return CGRect(x: 0, y: textY, width: canvasSize.width, height: textH)
        } else {
            let textY = canvasSize.height - border - textH
            return CGRect(x: border, y: textY, width: canvasSize.width - border * 2, height: textH)
        }
    }

    /// The text area content rect, excluding the divider border thickness.
    private var textAreaContentRect: CGRect {
        let t = vm.document.template
        let r = textAreaRect
        let innerBorder = t.innerBorderThickness
        if t.textAreaHasTopBorder {
            if t.textAreaPosition == .top {
                // Divider is at the bottom of the text area
                return CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - innerBorder)
            } else {
                // Divider is at the top of the text area
                return CGRect(x: r.minX, y: r.minY + innerBorder, width: r.width, height: r.height - innerBorder)
            }
        } else if !t.textAreaHasTopBorder && t.textAreaPosition == .bottom {
            // Outside border text area (e.g. Manga Report) — inset by its own border
            let tb = t.textAreaBorderThickness
            return CGRect(x: r.minX + tb, y: r.minY + tb, width: r.width - tb * 2, height: r.height - tb * 2)
        }
        return r
    }
}

// MARK: - Overlay Image View

struct OverlayImageView: View {
    @Binding var element: ImageElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )
        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0
        let h = baseSize * element.scale * pinchScale
        let w = h * aspectRatio

        Group {
            if let img = element.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w, height: h)
                    .rotationEffect(.degrees(element.rotation))
                    .overlay(
                        isSelected
                            ? RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.blue, lineWidth: 1.5)
                                .padding(-2)
                            : nil
                    )
                    .position(
                        x: center.x + dragOffset.width,
                        y: center.y + dragOffset.height
                    )
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in state = value.translation }
                                .onEnded { value in
                                    element.position = CGPoint(
                                        x: (center.x + value.translation.width) / canvasSize.width,
                                        y: (center.y + value.translation.height) / canvasSize.height
                                    )
                                },
                            MagnifyGesture()
                                .updating($pinchScale) { value, state, _ in state = value.magnification }
                                .onEnded { value in
                                    element.scale = max(0.1, element.scale * value.magnification)
                                }
                        )
                    )
                    .onTapGesture(perform: onTap)
            }
        }
    }
}

// MARK: - Text Element View

struct TextElementView: View {
    @Binding var element: TextElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )

        styledText
            .rotationEffect(.degrees(element.rotation))
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        .padding(-4)
                    : nil
            )
            .position(
                x: center.x + dragOffset.width,
                y: center.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        element.position = CGPoint(
                            x: (center.x + value.translation.width) / canvasSize.width,
                            y: (center.y + value.translation.height) / canvasSize.height
                        )
                    }
            )
            .onTapGesture(perform: onTap)
    }

    private var styledText: some View {
        CanvasTextView(element: element)
    }
}

// MARK: - Canvas Text View

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
        let padding: CGFloat = element.shadow.enabled ? element.shadow.radius * 2 + max(abs(element.shadow.offsetX), abs(element.shadow.offsetY)) : 0
        let renderSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
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
