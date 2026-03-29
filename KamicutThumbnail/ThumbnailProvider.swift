import QuickLookThumbnailing
import UIKit

class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let thumbnailURL = request.fileURL.appendingPathComponent("Thumbnail.jpg")

        guard FileManager.default.fileExists(atPath: thumbnailURL.path),
              let image = UIImage(contentsOfFile: thumbnailURL.path) else {
            handler(nil, CocoaError(.fileReadNoSuchFile))
            return
        }

        let maxSize = request.maximumSize
        let imageSize = image.size
        let scale: CGFloat
        if imageSize.width / imageSize.height > maxSize.width / maxSize.height {
            scale = maxSize.width / imageSize.width
        } else {
            scale = maxSize.height / imageSize.height
        }
        let drawSize = CGSize(
            width: (imageSize.width * scale).rounded(.down),
            height: (imageSize.height * scale).rounded(.down)
        )

        let reply = QLThumbnailReply(contextSize: drawSize) { () -> Bool in
            image.draw(in: CGRect(origin: .zero, size: drawSize))
            return true
        }

        handler(reply, nil)
    }
}
