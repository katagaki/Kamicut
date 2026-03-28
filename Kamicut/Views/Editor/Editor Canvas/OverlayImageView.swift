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

        // Rotate screen-space translation into local space
        let radians = -element.rotation * .pi / 180
        let localW = translation.width * cos(radians) - translation.height * sin(radians)
        let localH = translation.width * sin(radians) + translation.height * cos(radians)

        // Images always resize uniformly (aspect locked)
        let dx = handle.xFactor * localW
        let dy = handle.yFactor * localH
        let avg: CGFloat
        if handle.isCorner {
            avg = (dx + dy) / 2
        } else if handle.xFactor != 0 {
            avg = dx
        } else {
            avg = dy
        }

        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let scaleDelta = avg / baseSize
        let newScale = max(0.1, startScale + scaleDelta)

        // Compute position shift to anchor opposite edge
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0
        let startH = baseSize * startScale
        let startW = startH * aspectRatio
        let newH = baseSize * newScale
        let newW = newH * aspectRatio
        let dw = newW - startW
        let dh = newH - startH

        let localShiftX = (dw / canvasSize.width) * handle.anchorShiftX
        let localShiftY = (dh / canvasSize.height) * handle.anchorShiftY
        let rotBack = element.rotation * .pi / 180
        let canvasShiftX = localShiftX * cos(rotBack) - localShiftY * sin(rotBack)
        let canvasShiftY = localShiftX * sin(rotBack) + localShiftY * cos(rotBack)

        element.scale = newScale
        element.position = CGPoint(
            x: startPos.x + canvasShiftX,
            y: startPos.y + canvasShiftY
        )
    }
}
