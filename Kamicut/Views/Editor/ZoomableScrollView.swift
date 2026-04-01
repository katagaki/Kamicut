import SwiftUI

/// A UIScrollView-backed zoomable container that provides native
/// pinch-to-zoom with correct anchor point behavior.
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    var minZoom: CGFloat
    var maxZoom: CGFloat
    /// Extra bottom inset (e.g. for a toolbar that overlaps the scroll view).
    var additionalBottomInset: CGFloat
    /// The size to fit into view on initial zoom (e.g. the actual canvas, not the full scrollable content).
    var focalSize: CGSize?
    /// Changing this value triggers a re-zoom to fit the focal size.
    var zoomResetToken: Int
    @ViewBuilder var content: () -> Content

    init(minZoom: CGFloat = 0.1, maxZoom: CGFloat = 10.0,
         additionalBottomInset: CGFloat = 0,
         focalSize: CGSize? = nil,
         zoomResetToken: Int = 0,
         @ViewBuilder content: @escaping () -> Content) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.additionalBottomInset = additionalBottomInset
        self.focalSize = focalSize
        self.zoomResetToken = zoomResetToken
        self.content = content
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = LayoutAwareScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear
        scrollView.keyboardDismissMode = .interactive
        scrollView.coordinator = context.coordinator

        let hosted = context.coordinator.hostingController
        hosted.rootView = content()
        hosted.view.backgroundColor = .clear

        scrollView.addSubview(hosted.view)
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.hostingController.rootView = content()

        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom

        // Size the hosted view to its intrinsic SwiftUI size, only update if changed
        let size = coordinator.hostingController.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                                         height: CGFloat.greatestFiniteMagnitude))
        if coordinator.hostingController.view.bounds.size != size {
            coordinator.hostingController.view.frame = CGRect(origin: .zero, size: size)
            scrollView.contentSize = size
        }

        coordinator.additionalBottomInset = additionalBottomInset
        coordinator.focalSize = focalSize
        if coordinator.lastZoomResetToken != zoomResetToken {
            coordinator.lastZoomResetToken = zoomResetToken
            coordinator.resetZoom()
        }
    }

    /// UIScrollView subclass that triggers initial zoom after layout is complete,
    /// ensuring bounds and safeAreaInsets are accurate.
    class LayoutAwareScrollView: UIScrollView {
        weak var coordinator: Coordinator?

        override func layoutSubviews() {
            super.layoutSubviews()
            coordinator?.applyInitialZoomIfNeeded(scrollView: self)
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController = UIHostingController<Content?>(rootView: nil)
        weak var scrollView: UIScrollView?
        var hasAppliedInitialZoom = false
        var lastZoomResetToken: Int = 0
        var additionalBottomInset: CGFloat = 0
        var focalSize: CGSize?

        /// Padding fraction around the content when fitting to view (e.g. 0.05 = 5% padding on each side).
        private let fitPadding: CGFloat = 0.05

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

        func applyInitialZoomIfNeeded(scrollView: UIScrollView) {
            guard !hasAppliedInitialZoom else { return }
            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize
            guard boundsSize.width > 0, boundsSize.height > 0,
                  contentSize.width > 0, contentSize.height > 0 else { return }
            hasAppliedInitialZoom = true

            // Use focalSize (the actual canvas) for zoom calculation, not the full content
            let targetSize = focalSize ?? contentSize
            let safeArea = scrollView.safeAreaInsets
            let usableWidth = boundsSize.width - safeArea.left - safeArea.right
            let usableHeight = boundsSize.height - safeArea.top - safeArea.bottom - additionalBottomInset
            let paddedWidth = usableWidth * (1 - fitPadding * 2)
            let paddedHeight = usableHeight * (1 - fitPadding * 2)
            let fitZoom = min(paddedWidth / targetSize.width, paddedHeight / targetSize.height)
            let clampedZoom = min(max(fitZoom, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            scrollView.zoomScale = clampedZoom
            centerContent(in: scrollView)

            // Scroll to center of content, shifted up to account for bottom toolbar
            guard let contentView = hostingController.view else { return }
            let scaledW = contentView.frame.width
            let scaledH = contentView.frame.height
            let inset = scrollView.contentInset
            let offsetX = (scaledW - boundsSize.width) / 2 + inset.left
            let offsetY = (scaledH - boundsSize.height) / 2 + inset.top - additionalBottomInset / 2
            scrollView.contentOffset = CGPoint(
                x: max(offsetX, -inset.left),
                y: max(offsetY, -inset.top)
            )
        }

        func resetZoom() {
            hasAppliedInitialZoom = false
            guard let scrollView else { return }
            scrollView.setNeedsLayout()
        }
    }
}
