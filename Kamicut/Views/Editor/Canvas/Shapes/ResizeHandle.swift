import SwiftUI

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
