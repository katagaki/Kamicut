import SwiftUI

struct PolygonShape: InsettableShape {
    var sides: Int
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)

        // Compute unit vertices centered at origin with radius 1
        var xCoords: [CGFloat] = []
        var yCoords: [CGFloat] = []
        for index in 0..<sides {
            let angle = (CGFloat(index) * 2 * .pi / CGFloat(sides)) - .pi / 2
            xCoords.append(cos(angle))
            yCoords.append(sin(angle))
        }

        // Normalize to fill rect
        let minX = xCoords.min()!, maxX = xCoords.max()!
        let minY = yCoords.min()!, maxY = yCoords.max()!
        let scaleX = insetRect.width / (maxX - minX)
        let scaleY = insetRect.height / (maxY - minY)

        return Path { path in
            for index in 0..<sides {
                let point = CGPoint(
                    x: insetRect.minX + (xCoords[index] - minX) * scaleX,
                    y: insetRect.minY + (yCoords[index] - minY) * scaleY
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
