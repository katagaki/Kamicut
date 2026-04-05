import QuickLookThumbnailing
import UIKit
import ImageIO

class ThumbnailProvider: QLThumbnailProvider {

    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?

        coordinator.coordinate(
            readingItemAt: request.fileURL,
            options: .withoutChanges,
            error: &coordinatorError
        ) { accessedURL in
            generateThumbnail(from: accessedURL, request: request, handler: handler)
        }

        if let error = coordinatorError {
            handler(nil, error)
        }
    }

    private func generateThumbnail(
        from accessedURL: URL,
        request: QLFileThumbnailRequest,
        handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let thumbnailURL = accessedURL.appendingPathComponent("Thumbnail.jpg")

        guard FileManager.default.fileExists(atPath: thumbnailURL.path) else {
            handler(nil, CocoaError(.fileReadNoSuchFile))
            return
        }

        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(thumbnailURL as CFURL, sourceOptions as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            handler(nil, CocoaError(.fileReadCorruptFile))
            return
        }

        let drawSize = calculateDrawSize(
            imageSize: CGSize(width: pixelWidth, height: pixelHeight),
            maxSize: request.maximumSize
        )

        let maxPixel = max(drawSize.width, drawSize.height) * request.scale
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, downsampleOptions as CFDictionary
        ) else {
            handler(nil, CocoaError(.fileReadCorruptFile))
            return
        }

        let reply = QLThumbnailReply(contextSize: drawSize) { () -> Bool in
            guard let context = UIGraphicsGetCurrentContext() else { return false }
            context.translateBy(x: 0, y: drawSize.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(origin: .zero, size: drawSize))
            return true
        }

        handler(reply, nil)
    }

    private func calculateDrawSize(imageSize: CGSize, maxSize: CGSize) -> CGSize {
        let scale: CGFloat
        if imageSize.width / imageSize.height > maxSize.width / maxSize.height {
            scale = maxSize.width / imageSize.width
        } else {
            scale = maxSize.height / imageSize.height
        }
        return CGSize(
            width: (imageSize.width * scale).rounded(.down),
            height: (imageSize.height * scale).rounded(.down)
        )
    }
}
