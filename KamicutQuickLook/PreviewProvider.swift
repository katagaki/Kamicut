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
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func preparePreviewOfFile(
        at url: URL,
        completionHandler handler: @escaping (Error?) -> Void
    ) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?

        coordinator.coordinate(
            readingItemAt: url,
            options: .withoutChanges,
            error: &coordinatorError
        ) { accessedURL in
            let thumbnailURL = accessedURL.appendingPathComponent("Thumbnail.jpg")
            guard let data = try? Data(contentsOf: thumbnailURL),
                  let image = UIImage(data: data) else {
                handler(CocoaError(.fileReadCorruptFile))
                return
            }
            DispatchQueue.main.async {
                self.imageView.image = image
                self.preferredContentSize = image.size
                handler(nil)
            }
        }

        if let error = coordinatorError {
            handler(error)
        }
    }
}
