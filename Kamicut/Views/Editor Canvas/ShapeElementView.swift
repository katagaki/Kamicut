import SwiftUI

struct ShapeElementView: View {
    @Binding var element: ShapeElement
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
        let w = element.size.width * canvasSize.width * element.scale * pinchScale
        let h = element.size.height * canvasSize.height * element.scale * pinchScale

        shapeView
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

    @ViewBuilder
    private var shapeView: some View {
        let fill = element.fillColor.color
        let stroke = element.strokeColor.color
        let lineWidth = element.strokeWidth

        switch element.shapeKind {
        case .rectangle:
            Rectangle()
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .circle:
            Circle()
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .ellipse:
            Ellipse()
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .triangle:
            TriangleShape()
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .star:
            StarShape()
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .pentagon:
            PolygonShape(sides: 5)
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        case .hexagon:
            PolygonShape(sides: 6)
                .fill(fill)
                .stroke(stroke, lineWidth: lineWidth)
        }
    }
}

// MARK: - Custom Shapes

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct StarShape: Shape {
    var points: Int = 5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let totalPoints = points * 2

        return Path { p in
            for i in 0..<totalPoints {
                let angle = (CGFloat(i) * .pi / CGFloat(points)) - .pi / 2
                let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
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
}

struct PolygonShape: Shape {
    var sides: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        return Path { p in
            for i in 0..<sides {
                let angle = (CGFloat(i) * 2 * .pi / CGFloat(sides)) - .pi / 2
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
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
}
