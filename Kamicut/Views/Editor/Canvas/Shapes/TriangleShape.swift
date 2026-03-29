import SwiftUI

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
