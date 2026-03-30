import ImageIO
import UIKit

enum ImageDownsampler {

    private static let cache = NSCache<NSString, UIImage>()

    /// Returns a display-sized image for the given element and target pixel size.
    /// Results are cached — repeated calls with the same parameters return instantly.
    /// Falls back to the full cached `UIImage` if downsampling fails.
    static func displayImage(for element: ImageElement, maxPixelSize: CGFloat) -> UIImage? {
        // Round to nearest 100px so small size variations don't create new entries
        let bucket = max(Int(ceil(maxPixelSize / 100.0)) * 100, 100)
        let key = "\(element.id)-\(element.imageData.count)-\(bucket)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let image = downsample(data: element.imageData, maxPixelSize: CGFloat(bucket))
            ?? element.uiImage
        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }

    /// Returns the pixel dimensions of the image without fully decoding it.
    static func imageSize(from data: Data) -> CGSize? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    /// Creates a thumbnail at the given maximum pixel dimension using ImageIO,
    /// which avoids decoding the full image into memory.
    static func downsample(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
