import SwiftUI

struct OverlayImageView: View {
    @Binding var element: ImageElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

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
        let height = baseSize * element.scale * pinchScale
        let width = height * aspectRatio
        let activeRotation = rotationActivated ? gestureRotation.degrees : 0

        let totalRotation = element.rotation + activeRotation
        let radians = totalRotation * .pi / 180
        let boundingW = abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingH = abs(width * sin(radians)) + abs(height * cos(radians))

        Group {
            if let img = element.uiImage {
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
                            .frame(width: boundingW, height: boundingH)
                            .overlay {
                                ForEach(ResizeHandle.allCases, id: \.self) { handle in
                                    imageHandleView(for: handle, width: boundingW, height: boundingH)
                                }
                            }
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

    private func imageHandleView(for handle: ResizeHandle, width: CGFloat, height: CGFloat) -> some View {
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
                        applyImageResize(handle: handle, translation: translation)
                    }
                    .onEnded { _ in
                        resizeStartScale = nil
                        resizeStartPosition = nil
                        resizeStartLocation = nil
                    }
            )
    }

    // MARK: - Resize Logic

    private func applyImageResize(handle: ResizeHandle, translation: CGSize) {
        guard let startScale = resizeStartScale, let startPos = resizeStartPosition else { return }

        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0
        let rot = element.rotation * .pi / 180
        let cosR = cos(rot), sinR = sin(rot)

        // Old pixel dimensions
        let oldH = baseSize * startScale
        let oldW = oldH * aspectRatio

        // Old bounding box half-sizes (axis-aligned)
        let oldBBHalfW = (abs(oldW * cosR) + abs(oldH * sinR)) / 2
        let oldBBHalfH = (abs(oldW * sinR) + abs(oldH * cosR)) / 2

        // Anchor: opposite bounding box corner in canvas pixel space
        let startCx = startPos.x * canvasSize.width
        let startCy = startPos.y * canvasSize.height
        let anchorX = startCx - handle.xFactor * oldBBHalfW
        let anchorY = startCy - handle.yFactor * oldBBHalfH

        // The dragged handle moves in screen space
        let draggedX = startCx + handle.xFactor * oldBBHalfW + translation.width
        let draggedY = startCy + handle.yFactor * oldBBHalfH + translation.height

        // New bounding box half-sizes from anchor to dragged corner
        let newBBHalfW = handle.xFactor != 0 ? abs(draggedX - anchorX) / 2 : oldBBHalfW
        let newBBHalfH = handle.yFactor != 0 ? abs(draggedY - anchorY) / 2 : oldBBHalfH

        // Images resize uniformly — compute scale from bounding box change.
        // Use the axis that the handle controls; for corners, average both.
        let scaleFromW = oldBBHalfW > 0 ? newBBHalfW / oldBBHalfW : 1
        let scaleFromH = oldBBHalfH > 0 ? newBBHalfH / oldBBHalfH : 1
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

        // New bounding box half-sizes
        let finalBBHalfW = (abs(newW * cosR) + abs(newH * sinR)) / 2
        let finalBBHalfH = (abs(newW * sinR) + abs(newH * cosR)) / 2

        // Solve for new center so the anchor bounding box corner stays fixed
        let newCx = anchorX + handle.xFactor * finalBBHalfW
        let newCy = anchorY + handle.yFactor * finalBBHalfH

        element.scale = newScale
        element.position = CGPoint(
            x: newCx / canvasSize.width,
            y: newCy / canvasSize.height
        )
    }
}
