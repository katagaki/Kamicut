import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Post Processing

extension CircleCutRenderer {

    func convertToBlackAndWhite(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter.photoEffectMono()
        filter.inputImage = ciImage
        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    func applyFormat(_ image: UIImage, settings: ExportSettings) -> UIImage {
        if settings.format == .jpg {
            guard let data = image.jpegData(compressionQuality: settings.jpegQuality),
                  let reloaded = UIImage(data: data) else { return image }
            return reloaded
        }
        return image
    }
}
