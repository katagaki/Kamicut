import UIKit

// MARK: - Space Number Drawing

extension CircleCutRenderer {

    func drawSpaceNumber(
        _ info: SpaceNumberInfo, in rect: CGRect, context: CGContext, alignment: NSTextAlignment = .center
    ) {
        let font = UIFont(name: info.fontName, size: info.fontSize) ?? UIFont.boldSystemFont(ofSize: info.fontSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: info.color.uiColor
        ]
        let str = info.text as NSString
        let size = str.size(withAttributes: attrs)
        let xPos: CGFloat
        switch alignment {
        case .left:
            xPos = rect.minX
        case .right:
            xPos = rect.maxX - size.width
        default:
            xPos = rect.minX + (rect.width - size.width) / 2
        }
        let yPos = rect.minY + (rect.height - size.height) / 2
        str.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: attrs)
    }
}
