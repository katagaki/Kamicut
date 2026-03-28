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
    @State private var resizeStartScale: CGFloat? = nil
    @State private var resizeStartPosition: CGPoint? = nil

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
        let h = baseSize * element.scale * pinchScale
        let w = h * aspectRatio
        let activeRotation = rotationActivated ? gestureRotation.degrees : 0

        let totalRotation = element.rotation + activeRotation
        let radians = totalRotation * .pi / 180
        let boundingW = abs(w * cos(radians)) + abs(h * sin(radians))
        let boundingH = abs(w * sin(radians)) + abs(h * cos(radians))

        Group {
            if let img = element.uiImage {
                ZStack {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: w, height: h)
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
                DragGesture()
                    .onChanged { value in
                        if resizeStartScale == nil {
                            resizeStartScale = element.scale
                            resizeStartPosition = element.position
                        }
                        applyImageResize(handle: handle, translation: value.translation)
                    }
                    .onEnded { _ in
                        resizeStartScale = nil
                        resizeStartPosition = nil
                    }
            )
    }

    // MARK: - Resize Logic

    private func applyImageResize(handle: ResizeHandle, translation: CGSize) {
        guard let startScale = resizeStartScale, let startPos = resizeStartPosition else { return }

        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0
        let rot = element.rotation * .pi / 180
        let cosR = cos(rot)
        let sinR = sin(rot)

        // Old pixel dimensions
        let oldH = baseSize * startScale
        let oldW = oldH * aspectRatio

        // Anchor point: opposite corner/edge in canvas pixel space
        let anchorLocalX = -handle.xFactor * oldW / 2
        let anchorLocalY = -handle.yFactor * oldH / 2
        let startCx = startPos.x * canvasSize.width
        let startCy = startPos.y * canvasSize.height
        let anchorX = startCx + anchorLocalX * cosR - anchorLocalY * sinR
        let anchorY = startCy + anchorLocalX * sinR + anchorLocalY * cosR

        // Compute new scale from drag translation rotated into local space
        let localDragW = translation.width * cos(-rot) - translation.height * sin(-rot)
        let localDragH = translation.width * sin(-rot) + translation.height * cos(-rot)

        // Images always resize uniformly (aspect locked)
        let dx = handle.xFactor * localDragW
        let dy = handle.yFactor * localDragH
        let avg: CGFloat
        if handle.isCorner {
            avg = (dx + dy) / 2
        } else if handle.xFactor != 0 {
            avg = dx
        } else {
            avg = dy
        }

        let scaleDelta = avg / baseSize
        let newScale = max(0.1, startScale + scaleDelta)

        // New pixel dimensions
        let newH = baseSize * newScale
        let newW = newH * aspectRatio

        // Recompute center so the anchor point stays fixed
        let newAnchorLocalX = -handle.xFactor * newW / 2
        let newAnchorLocalY = -handle.yFactor * newH / 2
        let newCx = anchorX - newAnchorLocalX * cosR + newAnchorLocalY * sinR
        let newCy = anchorY - newAnchorLocalX * sinR - newAnchorLocalY * cosR

        element.scale = newScale
        element.position = CGPoint(
            x: newCx / canvasSize.width,
            y: newCy / canvasSize.height
        )
    }
}
