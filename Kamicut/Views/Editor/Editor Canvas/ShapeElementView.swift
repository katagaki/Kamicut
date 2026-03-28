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

        // Compute the axis-aligned bounding box of the rotated shape
        let radians = element.rotation * .pi / 180
        let boundingW = abs(width * cos(radians)) + abs(height * sin(radians))
        let boundingH = abs(width * sin(radians)) + abs(height * cos(radians))

        ZStack {
            shapeView
                .frame(width: width, height: height)
                .rotationEffect(.degrees(element.rotation))

            if isSelected {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: boundingW, height: boundingH)
                    .overlay {
                        ForEach(ResizeHandle.allCases, id: \.self) { handle in
                            handleView(for: handle, width: boundingW, height: boundingH)
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
                DragGesture()
                    .onChanged { value in
                        if resizeStartSize == nil {
                            resizeStartSize = element.size
                            resizeStartPosition = element.position
                        }
                        applyResize(handle: handle, translation: value.translation)
                    }
                    .onEnded { _ in
                        resizeStartSize = nil
                        resizeStartPosition = nil
                    }
            )
    }

    // MARK: - Resize Logic

    private func applyResize(handle: ResizeHandle, translation: CGSize) {
        guard let startSize = resizeStartSize, let startPos = resizeStartPosition else { return }

        let scale = element.scale
        let rot = element.rotation * .pi / 180

        // Old element pixel sizes
        let oldW = startSize.width * canvasSize.width * scale
        let oldH = startSize.height * canvasSize.height * scale

        // Old bounding box half-sizes (axis-aligned)
        let oldBBHalfW = (abs(oldW * cos(rot)) + abs(oldH * sin(rot))) / 2
        let oldBBHalfH = (abs(oldW * sin(rot)) + abs(oldH * cos(rot))) / 2

        // Anchor: the opposite bounding box corner in canvas pixel space
        // Handles are on the bounding box, so the anchor is axis-aligned
        let startCx = startPos.x * canvasSize.width
        let startCy = startPos.y * canvasSize.height
        let anchorX = startCx - handle.xFactor * oldBBHalfW
        let anchorY = startCy - handle.yFactor * oldBBHalfH

        // Compute new size from drag translation rotated into local space
        let localDragW = translation.width * cos(-rot) - translation.height * sin(-rot)
        let localDragH = translation.width * sin(-rot) + translation.height * cos(-rot)

        let locked = element.shapeKind.aspectLocked
        var dx = handle.xFactor * localDragW
        var dy = handle.yFactor * localDragH

        if locked && handle.isCorner {
            let avg = (dx + dy) / 2
            dx = avg; dy = avg
        }

        // Edge handles: left/right only change width, top/bottom only change height
        let dw = handle.xFactor != 0 ? dx / (canvasSize.width * scale) : 0
        let dh = handle.yFactor != 0 ? dy / (canvasSize.height * scale) : 0
        let newW = max(minNormalized, startSize.width + dw)
        let newH = max(minNormalized, startSize.height + dh)

        // New element pixel sizes
        let newPixelW = newW * canvasSize.width * scale
        let newPixelH = newH * canvasSize.height * scale

        // New bounding box half-sizes
        let newBBHalfW = (abs(newPixelW * cos(rot)) + abs(newPixelH * sin(rot))) / 2
        let newBBHalfH = (abs(newPixelW * sin(rot)) + abs(newPixelH * cos(rot))) / 2

        // Solve for new center so the anchor bounding box corner stays fixed
        let newCx = anchorX + handle.xFactor * newBBHalfW
        let newCy = anchorY + handle.yFactor * newBBHalfH

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

// MARK: - Resize Handle

enum ResizeHandle: CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight

    var isCorner: Bool {
        switch self {
        case .topLeft, .topRight, .bottomLeft, .bottomRight: return true
        default: return false
        }
    }

    /// How much width changes per pixel of drag translation
    var xFactor: CGFloat {
        switch self {
        case .topLeft, .left, .bottomLeft: return -1
        case .topRight, .right, .bottomRight: return 1
        case .top, .bottom: return 0
        }
    }

    /// How much height changes per pixel of drag translation
    var yFactor: CGFloat {
        switch self {
        case .topLeft, .top, .topRight: return -1
        case .bottomLeft, .bottom, .bottomRight: return 1
        case .left, .right: return 0
        }
    }

    func position(in size: CGSize) -> CGPoint {
        let width = size.width
        let height = size.height
        switch self {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .top: return CGPoint(x: width / 2, y: 0)
        case .topRight: return CGPoint(x: width, y: 0)
        case .left: return CGPoint(x: 0, y: height / 2)
        case .right: return CGPoint(x: width, y: height / 2)
        case .bottomLeft: return CGPoint(x: 0, y: height)
        case .bottom: return CGPoint(x: width / 2, y: height)
        case .bottomRight: return CGPoint(x: width, y: height)
        }
    }
}

// MARK: - Custom Shapes

struct TriangleShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path { path in
            path.move(to: CGPoint(x: insetRect.midX, y: insetRect.minY))
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> TriangleShape {
        TriangleShape(insetAmount: insetAmount + amount)
    }
}

struct StarShape: InsettableShape {
    var points: Int = 5
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let totalPoints = points * 2
        let innerRatio: CGFloat = 0.4

        // Compute unit vertices centered at origin with radius 1
        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for index in 0..<totalPoints {
            let angle = (CGFloat(index) * .pi / CGFloat(points)) - .pi / 2
            let radius: CGFloat = index.isMultiple(of: 2) ? 1.0 : innerRatio
            xs.append(cos(angle) * radius)
            ys.append(sin(angle) * radius)
        }

        // Normalize to fill rect
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = insetRect.width / (maxX - minX)
        let scaleY = insetRect.height / (maxY - minY)

        return Path { path in
            for index in 0..<totalPoints {
                let point = CGPoint(
                    x: insetRect.minX + (xs[index] - minX) * scaleX,
                    y: insetRect.minY + (ys[index] - minY) * scaleY
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> StarShape {
        StarShape(points: points, insetAmount: insetAmount + amount)
    }
}

struct PolygonShape: InsettableShape {
    var sides: Int
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Compute unit vertices centered at origin with radius 1
        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for index in 0..<sides {
            let angle = (CGFloat(index) * 2 * .pi / CGFloat(sides)) - .pi / 2
            xs.append(cos(angle))
            ys.append(sin(angle))
        }

        // Normalize to fill rect
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = insetRect.width / (maxX - minX)
        let scaleY = insetRect.height / (maxY - minY)

        return Path { path in
            for index in 0..<sides {
                let point = CGPoint(
                    x: insetRect.minX + (xs[index] - minX) * scaleX,
                    y: insetRect.minY + (ys[index] - minY) * scaleY
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> PolygonShape {
        PolygonShape(sides: sides, insetAmount: insetAmount + amount)
    }
}
