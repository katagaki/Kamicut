import SwiftUI

struct OverlayImageView: View {
    @Binding var element: ImageElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.displayScale) private var displayScale
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var rotationActivated: Bool = false
    @State private var resizeStartScale: CGFloat?
    @State private var resizeStartPosition: CGPoint?
    @State private var resizeStartLocation: CGPoint?

    /// Rotation threshold in degrees before rotation kicks in.
    private let rotationThreshold: Double = 10
    private let handleSize: CGFloat = 10
    private let handleHitSize: CGFloat = 44

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )
        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0

        // Committed dimensions (used for downsample target)
        let committedHeight = baseSize * element.scale
        let committedWidth = committedHeight * aspectRatio

        // Live dimensions (includes transient pinch gesture)
        let height = committedHeight * pinchScale
        let width = committedWidth * pinchScale

        let activeRotation = rotationActivated ? gestureRotation.degrees : 0
        let totalRotation = element.rotation + activeRotation

        // Downsample to committed size; during pinch SwiftUI scales the same image
        let maxPixel = max(committedWidth, committedHeight) * displayScale
        let img: UIImage? = ImageDownsampler.displayImage(for: element, maxPixelSize: maxPixel)

        Group {
            if let img {
                ZStack {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: width, height: height)
                        .shadow(
                            color: element.shadow.enabled
                                ? element.shadow.color.color.opacity(Double(element.shadow.color.alpha))
                                : .clear,
                            radius: element.shadow.enabled ? element.shadow.radius : 0,
                            x: element.shadow.enabled ? element.shadow.offsetX : 0,
                            y: element.shadow.enabled ? element.shadow.offsetY : 0
                        )
                        .rotationEffect(.degrees(totalRotation))

                    if isSelected {
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: width, height: height)
                            .overlay {
                                ForEach(ResizeHandle.allCases, id: \.self) { handle in
                                    imageHandleView(for: handle, width: width, height: height, aspectRatio: aspectRatio)
                                }
                            }
                            .rotationEffect(.degrees(totalRotation))
                    }
                }
                    .position(
                        x: center.x + dragOffset.width,
                        y: center.y + dragOffset.height
                    )
                    .gesture(
                        isSelected
                            ? SimultaneousGesture(
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
                                ),
                                RotateGesture()
                                    .updating($gestureRotation) { value, state, _ in
                                        state = value.rotation
                                    }
                                    .onChanged { value in
                                        if !rotationActivated && abs(value.rotation.degrees) > rotationThreshold {
                                            rotationActivated = true
                                        }
                                    }
                                    .onEnded { value in
                                        if rotationActivated {
                                            element.rotation += value.rotation.degrees
                                        }
                                        rotationActivated = false
                                    }
                            )
                            : nil
                    )
                    .onTapGesture(perform: onTap)
            }
        }
    }

    // MARK: - Selection Overlay with Grab Handles

    private func imageHandleView(
        for handle: ResizeHandle, width: CGFloat,
        height: CGFloat, aspectRatio: CGFloat
    ) -> some View {
        let pos = handle.position(in: CGSize(width: width, height: height))
        return Circle()
            .fill(Color.white)
            .stroke(Color.blue, lineWidth: 1.5)
            .frame(width: handleSize, height: handleSize)
            .contentShape(Circle().size(width: handleHitSize, height: handleHitSize)
                .offset(x: (handleSize - handleHitSize) / 2, y: (handleSize - handleHitSize) / 2))
            .position(x: pos.x, y: pos.y)
            .gesture(
                DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        if resizeStartScale == nil {
                            resizeStartScale = element.scale
                            resizeStartPosition = element.position
                            resizeStartLocation = value.startLocation
                        }
                        guard let startLoc = resizeStartLocation else { return }
                        let translation = CGSize(
                            width: value.location.x - startLoc.x,
                            height: value.location.y - startLoc.y
                        )
                        applyImageResize(handle: handle, translation: translation, aspectRatio: aspectRatio)
                    }
                    .onEnded { _ in
                        resizeStartScale = nil
                        resizeStartPosition = nil
                        resizeStartLocation = nil
                    }
            )
    }

    // MARK: - Resize Logic

    private func applyImageResize(handle: ResizeHandle, translation: CGSize, aspectRatio: CGFloat) {
        guard let startScale = resizeStartScale, let startPos = resizeStartPosition else { return }

        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let rot = element.rotation * .pi / 180
        let cosR = cos(rot), sinR = sin(rot)

        // Old pixel dimensions
        let oldH = baseSize * startScale
        let oldW = oldH * aspectRatio

        // Project drag translation into the element's local (rotated) coordinate system
        let localDx =  translation.width * cosR + translation.height * sinR
        let localDy = -translation.width * sinR + translation.height * cosR

        // Images resize uniformly - compute scale from local-space change.
        let scaleFromW = oldW > 0 ? (oldW + handle.xFactor * localDx) / oldW : 1
        let scaleFromH = oldH > 0 ? (oldH + handle.yFactor * localDy) / oldH : 1
        let ratio: CGFloat
        if handle.isCorner {
            ratio = (scaleFromW + scaleFromH) / 2
        } else if handle.xFactor != 0 {
            ratio = scaleFromW
        } else {
            ratio = scaleFromH
        }

        let newScale = max(0.1, startScale * ratio)

        // New pixel dimensions
        let newH = baseSize * newScale
        let newW = newH * aspectRatio

        // Anchor: opposite edge/corner in local (unrotated) space
        let anchorLocalX = -handle.xFactor * oldW / 2
        let anchorLocalY = -handle.yFactor * oldH / 2

        // New local center relative to the anchor
        let newLocalCx = anchorLocalX + handle.xFactor * newW / 2
        let newLocalCy = anchorLocalY + handle.yFactor * newH / 2

        // For axes the handle doesn't affect, center stays at 0 in local space
        let effectiveLocalCx = handle.xFactor != 0 ? newLocalCx : 0
        let effectiveLocalCy = handle.yFactor != 0 ? newLocalCy : 0

        // Rotate local center offset back to canvas space and add to original center
        let startCx = startPos.x * canvasSize.width
        let startCy = startPos.y * canvasSize.height
        let newCx = startCx + effectiveLocalCx * cosR - effectiveLocalCy * sinR
        let newCy = startCy + effectiveLocalCx * sinR + effectiveLocalCy * cosR

        element.scale = newScale
        element.position = CGPoint(
            x: newCx / canvasSize.width,
            y: newCy / canvasSize.height
        )
    }
}
