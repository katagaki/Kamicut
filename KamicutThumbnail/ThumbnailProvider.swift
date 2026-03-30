import QuickLookThumbnailing
import UIKit
import ImageIO

class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let thumbnailURL = request.fileURL.appendingPathComponent("Thumbnail.jpg")

        // Use file coordination to safely read from the document package,
        // which may be open in the main app or syncing via iCloud.
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?

        coordinator.coordinate(
            readingItemAt: request.fileURL,
            options: .withoutChanges,
            error: &coordinatorError
        ) { accessedURL in
            let accessedThumbnailURL = accessedURL.appendingPathComponent("Thumbnail.jpg")

            guard FileManager.default.fileExists(atPath: accessedThumbnailURL.path) else {
                handler(nil, CocoaError(.fileReadNoSuchFile))
                return
            }

            // Use ImageIO to read image dimensions and downsample efficiently
            // without decoding the full image into memory.
            let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
            guard let source = CGImageSourceCreateWithURL(accessedThumbnailURL as CFURL, sourceOptions as CFDictionary),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
                  let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
                handler(nil, CocoaError(.fileReadCorruptFile))
                return
            }

            let imageSize = CGSize(width: pixelWidth, height: pixelHeight)
            let maxSize = request.maximumSize
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

            // Downsample to the exact target pixel size
            let maxPixel = max(drawSize.width, drawSize.height) * request.scale
            let downsampleOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
                handler(nil, CocoaError(.fileReadCorruptFile))
                return
            }

            let reply = QLThumbnailReply(contextSize: drawSize) { () -> Bool in
                let context = UIGraphicsGetCurrentContext()
                context?.draw(cgImage, in: CGRect(origin: .zero, size: drawSize))
                return true
            }

            handler(reply, nil)
        }

        if let error = coordinatorError {
            handler(nil, error)
        }
    }
}
