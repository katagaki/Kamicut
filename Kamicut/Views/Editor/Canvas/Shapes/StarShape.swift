import SwiftUI

struct StarShape: InsettableShape {
    var points: Int = 5
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let totalPoints = points * 2
        let innerRatio: CGFloat = 0.4

        // Compute unit vertices centered at origin with radius 1
        var xCoords: [CGFloat] = []
        var yCoords: [CGFloat] = []
        for index in 0..<totalPoints {
            let angle = (CGFloat(index) * .pi / CGFloat(points)) - .pi / 2
            let radius: CGFloat = index.isMultiple(of: 2) ? 1.0 : innerRatio
            xCoords.append(cos(angle) * radius)
            yCoords.append(sin(angle) * radius)
        }

        // Normalize to fill rect
        let minX = xCoords.min()!, maxX = xCoords.max()!
        let minY = yCoords.min()!, maxY = yCoords.max()!
        let scaleX = insetRect.width / (maxX - minX)
        let scaleY = insetRect.height / (maxY - minY)

        return Path { path in
            for index in 0..<totalPoints {
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

    func inset(by amount: CGFloat) -> StarShape {
        StarShape(points: points, insetAmount: insetAmount + amount)
    }
}
