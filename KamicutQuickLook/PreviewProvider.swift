import QuickLook
import UIKit

class PreviewViewController: UIViewController, QLPreviewingController {

    private let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func preparePreviewOfFile(
        at url: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }

        let thumbnailURL = url.appendingPathComponent("Thumbnail.jpg")
        guard let data = try? Data(contentsOf: thumbnailURL),
              let image = UIImage(data: data) else {
            handler(CocoaError(.fileReadCorruptFile))
            return
        }
        imageView.image = image
        preferredContentSize = image.size
        handler(nil)
    }
}
