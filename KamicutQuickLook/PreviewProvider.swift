import QuickLook
import UIKit
import UniformTypeIdentifiers

class PreviewProvider: QLPreviewProvider {

    nonisolated override func providePreview(
        for request: QLFilePreviewRequest
    ) async throws -> QLPreviewReply {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        let imageData: Data = try await withCheckedThrowingContinuation { continuation in
            var coordinatorError: NSError?
            coordinator.coordinate(
                readingItemAt: request.fileURL,
                options: .withoutChanges,
                error: &coordinatorError
            ) { accessedURL in
                let accessedThumbnailURL = accessedURL.appendingPathComponent("Thumbnail.jpg")
                do {
                    let data = try Data(contentsOf: accessedThumbnailURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            if let error = coordinatorError {
                continuation.resume(throwing: error)
            }
        }

        guard let image = UIImage(data: imageData) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let imageSize = image.size
        return QLPreviewReply(dataOfContentType: .jpeg, contentSize: imageSize) { _ in
            return imageData
        }
    }
}
