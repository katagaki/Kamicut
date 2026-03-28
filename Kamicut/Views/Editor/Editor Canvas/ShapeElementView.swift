import SwiftUI

struct ShapeElementView: View {
    @Binding var element: ShapeElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var resizeStartSize: CGSize? = nil
    @State private var resizeStartPosition: CGPoint? = nil

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
        let w = element.shapeKind.aspectLocked ? side : rawW
        let h = element.shapeKind.aspectLocked ? side : rawH

        // Compute the axis-aligned bounding box of the rotated shape
        let radians = element.rotation * .pi / 180
        let boundingW = abs(w * cos(radians)) + abs(h * sin(radians))
        let boundingH = abs(w * sin(radians)) + abs(h * cos(radians))

        ZStack {
            shapeView
                .frame(width: w, height: h)
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

        // Rotate screen-space translation into local (unrotated) space
        let radians = -element.rotation * .pi / 180
        let localW = translation.width * cos(radians) - translation.height * sin(radians)
        let localH = translation.width * sin(radians) + translation.height * cos(radians)

        let locked = element.shapeKind.aspectLocked
        var dx = handle.xFactor * localW
        var dy = handle.yFactor * localH

        if locked {
            if handle.isCorner {
                let avg = (dx + dy) / 2
                dx = avg
                dy = avg
            } else {
                if handle.xFactor != 0 {
                    dy = dx
                } else {
                    dx = dy
                }
            }
        }

        let scale = element.scale
        let dw = dx / (canvasSize.width * scale)
        let dh = dy / (canvasSize.height * scale)

        let newW = max(minNormalized, startSize.width + dw)
        let newH = max(minNormalized, startSize.height + dh)

        // Compute position shift to anchor opposite edge (in pixels)
        let pixelDW = (newW - startSize.width) * canvasSize.width * scale
        let pixelDH = (newH - startSize.height) * canvasSize.height * scale
        let localPixelShiftX = pixelDW * handle.anchorShiftX
        let localPixelShiftY = pixelDH * handle.anchorShiftY

        // Rotate pixel shift back to canvas space, then normalize
        let rotBack = element.rotation * .pi / 180
        let canvasPixelShiftX = localPixelShiftX * cos(rotBack) - localPixelShiftY * sin(rotBack)
        let canvasPixelShiftY = localPixelShiftX * sin(rotBack) + localPixelShiftY * cos(rotBack)

        element.size = CGSize(width: newW, height: newH)
        element.position = CGPoint(
            x: startPos.x + canvasPixelShiftX / canvasSize.width,
            y: startPos.y + canvasPixelShiftY / canvasSize.height
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

    /// Position shift to keep opposite edge anchored (0.5 = half the size delta)
    var anchorShiftX: CGFloat {
        switch self {
        case .topLeft, .left, .bottomLeft: return -0.5
        case .topRight, .right, .bottomRight: return 0.5
        case .top, .bottom: return 0
        }
    }

    var anchorShiftY: CGFloat {
        switch self {
        case .topLeft, .top, .topRight: return -0.5
        case .bottomLeft, .bottom, .bottomRight: return 0.5
        case .left, .right: return 0
        }
    }

    func position(in size: CGSize) -> CGPoint {
        let w = size.width
        let h = size.height
        switch self {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .top: return CGPoint(x: w / 2, y: 0)
        case .topRight: return CGPoint(x: w, y: 0)
        case .left: return CGPoint(x: 0, y: h / 2)
        case .right: return CGPoint(x: w, y: h / 2)
        case .bottomLeft: return CGPoint(x: 0, y: h)
        case .bottom: return CGPoint(x: w / 2, y: h)
        case .bottomRight: return CGPoint(x: w, y: h)
        }
    }
}

// MARK: - Custom Shapes

struct TriangleShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return Path { p in
            p.move(to: CGPoint(x: r.midX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
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
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let totalPoints = points * 2
        let innerRatio: CGFloat = 0.4

        // Compute unit vertices centered at origin with radius 1
        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for i in 0..<totalPoints {
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
            let radius: CGFloat = i.isMultiple(of: 2) ? 1.0 : innerRatio
            xs.append(cos(angle) * radius)
            ys.append(sin(angle) * radius)
        }

        // Normalize to fill rect
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = r.width / (maxX - minX)
        let scaleY = r.height / (maxY - minY)

        return Path { p in
            for i in 0..<totalPoints {
                let point = CGPoint(
                    x: r.minX + (xs[i] - minX) * scaleX,
                    y: r.minY + (ys[i] - minY) * scaleY
                )
                if i == 0 {
                    p.move(to: point)
                } else {
                    p.addLine(to: point)
                }
            }
            p.closeSubpath()
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
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Compute unit vertices centered at origin with radius 1
        var xs: [CGFloat] = []
        var ys: [CGFloat] = []
        for i in 0..<sides {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(sides)) - .pi / 2
            xs.append(cos(angle))
            ys.append(sin(angle))
        }

        // Normalize to fill rect
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let scaleX = r.width / (maxX - minX)
        let scaleY = r.height / (maxY - minY)

        return Path { p in
            for i in 0..<sides {
                let point = CGPoint(
                    x: r.minX + (xs[i] - minX) * scaleX,
                    y: r.minY + (ys[i] - minY) * scaleY
                )
                if i == 0 {
                    p.move(to: point)
                } else {
                    p.addLine(to: point)
                }
            }
            p.closeSubpath()
        }
    }

    func inset(by amount: CGFloat) -> PolygonShape {
        PolygonShape(sides: sides, insetAmount: insetAmount + amount)
    }
}
