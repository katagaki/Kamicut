import UIKit

// MARK: - Shape Path Helpers

extension CircleCutRenderer {

    func trianglePath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    func starPath(in rect: CGRect, points: Int) -> CGPath {
        let totalPoints = points * 2
        let innerRatio: CGFloat = 0.4

        var xCoords: [CGFloat] = []
        var yCoords: [CGFloat] = []
        for index in 0..<totalPoints {
            let angle = (CGFloat(index) * .pi / CGFloat(points)) - .pi / 2
            let radius: CGFloat = index.isMultiple(of: 2) ? 1.0 : innerRatio
            xCoords.append(cos(angle) * radius)
            yCoords.append(sin(angle) * radius)
        }

        return normalizedPolygonPath(xCoords: xCoords, yCoords: yCoords, count: totalPoints, in: rect)
    }

    func polygonPath(in rect: CGRect, sides: Int) -> CGPath {
        var xCoords: [CGFloat] = []
        var yCoords: [CGFloat] = []
        for index in 0..<sides {
            let angle = (CGFloat(index) * 2 * .pi / CGFloat(sides)) - .pi / 2
            xCoords.append(cos(angle))
            yCoords.append(sin(angle))
        }

        return normalizedPolygonPath(xCoords: xCoords, yCoords: yCoords, count: sides, in: rect)
    }

    // MARK: - Private

    private func normalizedPolygonPath(xCoords: [CGFloat], yCoords: [CGFloat], count: Int, in rect: CGRect) -> CGPath {
        let minX = xCoords.min()!, maxX = xCoords.max()!
        let minY = yCoords.min()!, maxY = yCoords.max()!
        let scaleX = rect.width / (maxX - minX)
        let scaleY = rect.height / (maxY - minY)

        let path = CGMutablePath()
        for index in 0..<count {
            let point = CGPoint(
                x: rect.minX + (xCoords[index] - minX) * scaleX,
                y: rect.minY + (yCoords[index] - minY) * scaleY
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
