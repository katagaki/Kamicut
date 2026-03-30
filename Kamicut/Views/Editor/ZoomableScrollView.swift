import SwiftUI

/// A UIScrollView-backed zoomable container that provides native
/// pinch-to-zoom with correct anchor point behavior.
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    var minZoom: CGFloat
    var maxZoom: CGFloat
    @ViewBuilder var content: () -> Content

    init(minZoom: CGFloat = 0.1, maxZoom: CGFloat = 10.0, @ViewBuilder content: @escaping () -> Content) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .interactive

        let hosted = context.coordinator.hostingController
        hosted.rootView = content()
        hosted.view.backgroundColor = .clear

        scrollView.addSubview(hosted.view)
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.hostingController.rootView = content()

        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom

        // Size the hosted view to its intrinsic SwiftUI size
        let size = coordinator.hostingController.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                         height: CGFloat.greatestFiniteMagnitude))
        coordinator.hostingController.view.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size

        coordinator.centerContent(in: scrollView)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController = UIHostingController<Content?>(rootView: nil)
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
        }

        func centerContent(in scrollView: UIScrollView) {
            guard let view = hostingController.view else { return }
            let offsetX = max((scrollView.bounds.width - view.frame.width) / 2, 0)
            let offsetY = max((scrollView.bounds.height - view.frame.height) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
        }
    }
}
