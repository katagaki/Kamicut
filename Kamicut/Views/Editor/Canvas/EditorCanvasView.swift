import SwiftUI

// MARK: - Editor Canvas View

struct EditorCanvasView: View {
    @Bindable var editor: EditorState

    // Cached background image to avoid re-decoding every render
    @State private var cachedBackgroundImage: UIImage?
    @State private var cachedBackgroundDataHash: Int = 0
    @State private var cachedBackgroundMaxPixel: CGFloat = 0

    private var canvasSize: CGSize { editor.document.template.canvasSize }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Canvas background
            canvasBackground

            // Background image (image area only, unless bleed)
            if let img = cachedBackgroundImage {
                backgroundImageLayer(img)
            }

            // Layers (images and text in unified z-order)
            ForEach(Array(editor.document.layers.enumerated()), id: \.element.id) { index, layer in
                let isSelected = isLayerSelected(layer)
                Group {
                    switch layer {
                    case .image(let imageEl):
                        OverlayImageView(
                            element: Binding(
                                get: {
                                    if case .image(let img) = editor.document.layers[safe: index] { return img }
                                    return imageEl
                                },
                                set: { editor.document.layers[index] = .image($0) }
                            ),
                            canvasSize: canvasSize,
                            isSelected: isSelected,
                            onTap: { editor.selectLayer(id: imageEl.id) }
                        )
                    case .text(let textEl):
                        TextElementView(
                            element: Binding(
                                get: {
                                    if case .text(let txt) = editor.document.layers[safe: index] { return txt }
                                    return textEl
                                },
                                set: { editor.document.layers[index] = .text($0) }
                            ),
                            canvasSize: canvasSize,
                            isSelected: isSelected,
                            onTap: { editor.selectLayer(id: textEl.id) }
                        )
                    case .shape(let shapeEl):
                        ShapeElementView(
                            element: Binding(
                                get: {
                                    if case .shape(let shp) = editor.document.layers[safe: index] { return shp }
                                    return shapeEl
                                },
                                set: { editor.document.layers[index] = .shape($0) }
                            ),
                            canvasSize: canvasSize,
                            isSelected: isSelected,
                            onTap: { editor.selectLayer(id: shapeEl.id) }
                        )
                    }
                }
                .zIndex(isSelected ? 1 : 0)
            }

            // Text area
            textAreaOverlay

            // Checkbox area
            checkboxAreaOverlay

            // Border
            canvasBorder

            // Space number (topmost layer)
            spaceNumberOverlay
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .coordinateSpace(name: "canvas")
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            editor.selectedImageID = nil
            editor.selectedTextID = nil
            editor.selectedShapeID = nil
        }
        .onAppear { updateCachedBackgroundImage() }
        .onChange(of: editor.document.backgroundImage?.imageData) { updateCachedBackgroundImage() }
        .onChange(of: editor.bleedOption) { updateCachedBackgroundImage() }
        .onChange(of: editor.document.template.canvasSize) { updateCachedBackgroundImage() }
    }

    // MARK: - Background Image Cache

    private func updateCachedBackgroundImage() {
        guard let bgImage = editor.document.backgroundImage else {
            cachedBackgroundImage = nil
            return
        }
        let dataHash = bgImage.imageData.hashValue
        let maxPixel = max(canvasSize.width, canvasSize.height) * UIScreen.main.scale
        let dataChanged = dataHash != cachedBackgroundDataHash
        let sizeRatio = cachedBackgroundMaxPixel > 0 ? maxPixel / cachedBackgroundMaxPixel : 0
        let sizeChanged = sizeRatio < 0.8 || sizeRatio > 1.2
        guard dataChanged || sizeChanged else { return }
        cachedBackgroundDataHash = dataHash
        cachedBackgroundMaxPixel = maxPixel
        cachedBackgroundImage = ImageDownsampler.downsample(data: bgImage.imageData, maxPixelSize: maxPixel)
    }

    // MARK: - Helpers

    private func isLayerSelected(_ layer: CanvasLayer) -> Bool {
        switch layer {
        case .image(let img): return editor.selectedImageID == img.id
        case .text(let txt): return editor.selectedTextID == txt.id
        case .shape(let shp): return editor.selectedShapeID == shp.id
        }
    }

    // MARK: - Subviews

    private var canvasBackground: some View {
        Rectangle()
            .fill(editor.document.backgroundColor?.color ?? Color.white)
            .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private func backgroundImageLayer(_ uiImg: UIImage) -> some View {
        let template = editor.document.template
        let border = template.outerBorderThickness
        let imgAreaH = imageAreaHeight
        let imageAreaY: CGFloat
        if editor.bleedOption == .full {
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
                width: editor.bleedOption == .full ? canvasSize.width : canvasSize.width - border * 2,
                height: editor.bleedOption == .full ? canvasSize.height : imgAreaH
            )
            .clipped()
            .offset(x: editor.bleedOption == .full ? 0 : border, y: imageAreaY)
            .allowsHitTesting(false)
    }

    private var textAreaOverlay: some View {
        let template = editor.document.template
        guard template.textAreaEnabled else { return AnyView(EmptyView()) }
        let border = template.outerBorderThickness
        let textH = template.textAreaHeight
        let textY: CGFloat
        let textX: CGFloat
        let textW: CGFloat
        if template.textAreaPosition == .top {
            textY = border
            if template.checkboxAreaEnabled {
                let boxTotalW = border + template.checkboxAreaSize.width
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

    private var checkboxAreaOverlay: some View {
        let template = editor.document.template
        guard template.checkboxAreaEnabled else { return AnyView(EmptyView()) }
        let border = template.outerBorderThickness
        let innerBorder = template.innerBorderThickness
        let boxW = template.checkboxAreaSize.width
        let boxH = template.checkboxAreaSize.height
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
        let template = editor.document.template
        let spaceNum = editor.spaceNumber
        guard !spaceNum.text.isEmpty else { return AnyView(EmptyView()) }

        let font = Font.custom(spaceNum.fontName, size: spaceNum.fontSize)
        let color = spaceNum.color.color

        switch spaceNum.position {
        case .textArea:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let rect = textAreaContentRect
            return AnyView(
                Text(spaceNum.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
                    .allowsHitTesting(false)
            )

        case .textAreaLeading:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let rect = textAreaContentRect
            return AnyView(
                Text(spaceNum.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .padding(.leading, 8)
                    .frame(width: rect.width, height: rect.height, alignment: .leading)
                    .offset(x: rect.minX, y: rect.minY)
                    .allowsHitTesting(false)
            )

        case .textAreaTrailing:
            guard template.textAreaEnabled else { return AnyView(EmptyView()) }
            let rect = textAreaContentRect
            return AnyView(
                Text(spaceNum.text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .padding(.trailing, 8)
                    .frame(width: rect.width, height: rect.height, alignment: .trailing)
                    .offset(x: rect.minX, y: rect.minY)
                    .allowsHitTesting(false)
            )

        case .imageTopLeft, .imageTopRight, .imageBottomLeft, .imageBottomRight:
            let border = template.outerBorderThickness
            let imgAreaH = imageAreaHeight
            let imageAreaY: CGFloat = (template.textAreaEnabled && template.textAreaPosition == .top)
                ? border + template.textAreaHeight : border
            let alignment: Alignment = {
                switch spaceNum.position {
                case .imageTopLeft: return .topLeading
                case .imageTopRight: return .topTrailing
                case .imageBottomLeft: return .bottomLeading
                case .imageBottomRight: return .bottomTrailing
                default: return .center
                }
            }()
            return AnyView(
                Text(spaceNum.text)
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

}

// MARK: - Geometry Helpers & Border

extension EditorCanvasView {
    var canvasBorder: some View {
        let template = editor.document.template
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

    var imageAreaHeight: CGFloat {
        let template = editor.document.template
        let border = template.outerBorderThickness
        if template.textAreaEnabled && !template.textAreaHasTopBorder && template.textAreaPosition == .bottom {
            // Text area is outside the outer border
            return canvasSize.height - template.textAreaHeight - border * 2
        }
        let textH = template.textAreaEnabled ? template.textAreaHeight : 0
        return canvasSize.height - border * 2 - textH
    }

    /// The text area rect, positioned after the outer border and to the right of the checkbox area when at top.
    var textAreaRect: CGRect {
        let template = editor.document.template
        let border = template.outerBorderThickness
        let textH = template.textAreaHeight
        if template.textAreaPosition == .top {
            let textY = border
            if template.checkboxAreaEnabled {
                let boxTotalW = border + template.checkboxAreaSize.width
                return CGRect(x: boxTotalW, y: textY, width: canvasSize.width - boxTotalW - border, height: textH)
            }
            return CGRect(x: border, y: textY, width: canvasSize.width - border * 2, height: textH)
        } else if !template.textAreaHasTopBorder {
            // Text area outside the outer border
            let textY = canvasSize.height - textH
            return CGRect(x: 0, y: textY, width: canvasSize.width, height: textH)
        } else {
            let textY = canvasSize.height - border - textH
            return CGRect(x: border, y: textY, width: canvasSize.width - border * 2, height: textH)
        }
    }

    /// The text area content rect, excluding the divider border thickness.
    var textAreaContentRect: CGRect {
        let template = editor.document.template
        let rect = textAreaRect
        let innerBorder = template.innerBorderThickness
        if template.textAreaHasTopBorder {
            if template.textAreaPosition == .top {
                // Divider is at the bottom of the text area
                return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - innerBorder)
            } else {
                // Divider is at the top of the text area
                return CGRect(
                    x: rect.minX, y: rect.minY + innerBorder,
                    width: rect.width, height: rect.height - innerBorder
                )
            }
        } else if !template.textAreaHasTopBorder && template.textAreaPosition == .bottom {
            // Outside border text area (e.g. Manga Report) - inset by its own border
            let borderThickness = template.textAreaBorderThickness
            return CGRect(
                x: rect.minX + borderThickness, y: rect.minY + borderThickness,
                width: rect.width - borderThickness * 2, height: rect.height - borderThickness * 2
            )
        }
        return rect
    }
}
