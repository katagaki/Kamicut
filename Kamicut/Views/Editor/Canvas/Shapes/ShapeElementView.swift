import SwiftUI

struct ShapeElementView: View {
    @Binding var element: ShapeElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var resizeStartSize: CGSize?
    @State private var resizeStartPosition: CGPoint?
    @State private var resizeStartLocation: CGPoint?

    private let handleSize: CGFloat = 10
    private let handleHitSize: CGFloat = 44
    private let minNormalized: CGFloat = 0.02

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )
        let rawW = element.size.width * canvasSize.width * element.scale * pinchScale
        let rawH = element.size.height * canvasSize.height * element.scale * pinchScale
        let side = min(rawW, rawH)
        let width = element.shapeKind.aspectLocked ? side : rawW
        let height = element.shapeKind.aspectLocked ? side : rawH

        ZStack {
            shapeView
                .frame(width: width, height: height)
                .rotationEffect(.degrees(element.rotation))

            if isSelected {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: width, height: height)
                    .overlay {
                        ForEach(ResizeHandle.allCases, id: \.self) { handle in
                            handleView(for: handle, width: width, height: height)
                        }
                    }
                    .rotationEffect(.degrees(element.rotation))
            }
        }
        .position(
                x: center.x + dragOffset.width,
                y: center.y + dragOffset.height
            )
            .gesture(
                isSelected
                    ? SimultaneousGesture(
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
                    : nil
            )
            .onTapGesture(perform: onTap)
    }

    // MARK: - Selection Overlay with Grab Handles

    private func handleView(for handle: ResizeHandle, width: CGFloat, height: CGFloat) -> some View {
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
                        if resizeStartSize == nil {
                            resizeStartSize = element.size
                            resizeStartPosition = element.position
                            resizeStartLocation = value.startLocation
                        }
                        guard let startLoc = resizeStartLocation else { return }
                        let translation = CGSize(
                            width: value.location.x - startLoc.x,
                            height: value.location.y - startLoc.y
                        )
                        applyResize(handle: handle, translation: translation)
                    }
                    .onEnded { _ in
                        resizeStartSize = nil
                        resizeStartPosition = nil
                        resizeStartLocation = nil
                    }
            )
    }

    // MARK: - Resize Logic

    private func applyResize(handle: ResizeHandle, translation: CGSize) {
        guard let startSize = resizeStartSize, let startPos = resizeStartPosition else { return }

        let scale = element.scale
        let rot = element.rotation * .pi / 180
        let cosR = cos(rot), sinR = sin(rot)

        // Old element pixel sizes
        let oldW = startSize.width * canvasSize.width * scale
        let oldH = startSize.height * canvasSize.height * scale

        // Project drag translation into the element's local (rotated) coordinate system.
        // This avoids the ill-conditioned bounding-box inversion that breaks near 45°/135°.
        let localDx =  translation.width * cosR + translation.height * sinR
        let localDy = -translation.width * sinR + translation.height * cosR

        // Apply handle factors: xFactor/yFactor tell us which axes this handle affects
        // and in which direction (+1 = right/bottom edge, -1 = left/top edge, 0 = no change)
        var newPixelW = oldW + handle.xFactor * localDx
        var newPixelH = oldH + handle.yFactor * localDy

        // Prevent flipping
        newPixelW = max(minNormalized * canvasSize.width * scale, newPixelW)
        newPixelH = max(minNormalized * canvasSize.height * scale, newPixelH)

        let locked = element.shapeKind.aspectLocked
        if locked {
            let side = min(newPixelW, newPixelH)
            newPixelW = side
            newPixelH = side
        }

        // Convert back to normalized sizes
        let newW = max(minNormalized, newPixelW / (canvasSize.width * scale))
        let newH = max(minNormalized, newPixelH / (canvasSize.height * scale))

        // Recompute final pixel sizes after clamping
        let finalPixelW = newW * canvasSize.width * scale
        let finalPixelH = newH * canvasSize.height * scale

        // The anchor is the opposite edge/corner in local space.
        // In local (unrotated) coordinates, the element spans from -oldW/2 to +oldW/2.
        // The anchor local point is the side opposite to the handle.
        let anchorLocalX = -handle.xFactor * oldW / 2
        let anchorLocalY = -handle.yFactor * oldH / 2

        // The new local center relative to the anchor
        let newLocalCx = anchorLocalX + handle.xFactor * finalPixelW / 2
        let newLocalCy = anchorLocalY + handle.yFactor * finalPixelH / 2

        // For axes the handle doesn't affect, the center stays at 0 in local space
        let effectiveLocalCx = handle.xFactor != 0 ? newLocalCx : 0
        let effectiveLocalCy = handle.yFactor != 0 ? newLocalCy : 0

        // Rotate the local center offset back to canvas space and add to original center
        let startCx = startPos.x * canvasSize.width
        let startCy = startPos.y * canvasSize.height
        let newCx = startCx + effectiveLocalCx * cosR - effectiveLocalCy * sinR
        let newCy = startCy + effectiveLocalCx * sinR + effectiveLocalCy * cosR

        element.size = CGSize(width: newW, height: newH)
        element.position = CGPoint(
            x: newCx / canvasSize.width,
            y: newCy / canvasSize.height
        )
    }

    @ViewBuilder
    private var shapeView: some View {
        let fill = element.fillColor.color
        let stroke = element.strokeColor.color
        let lineWidth = element.strokeWidth

        switch element.shapeKind {
        case .square, .rectangle:
            Rectangle()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .circle:
            Circle()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .ellipse:
            Ellipse()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .star:
            StarShape()
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .pentagon:
            PolygonShape(sides: 5)
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        case .hexagon:
            PolygonShape(sides: 6)
                .fill(fill)
                .strokeBorder(stroke, lineWidth: lineWidth)
        }
    }
}

