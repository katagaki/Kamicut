import SwiftUI

struct OverlayImageView: View {
    @Binding var element: ImageElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    @State private var rotationActivated: Bool = false

    /// Rotation threshold in degrees before rotation kicks in.
    private let rotationThreshold: Double = 10

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )
        let baseSize = min(canvasSize.width, canvasSize.height) * 0.4
        let aspectRatio = element.uiImage.map { $0.size.width / $0.size.height } ?? 1.0
        let h = baseSize * element.scale * pinchScale
        let w = h * aspectRatio
        let activeRotation = rotationActivated ? gestureRotation.degrees : 0

        Group {
            if let img = element.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: w, height: h)
                    .rotationEffect(.degrees(element.rotation + activeRotation))
                    .overlay(
                        isSelected
                            ? RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.blue, lineWidth: 1.5)
                                .padding(-2)
                            : nil
                    )
                    .position(
                        x: center.x + dragOffset.width,
                        y: center.y + dragOffset.height
                    )
                    .gesture(
                        SimultaneousGesture(
                            SimultaneousGesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in state = value.translation }
                                    .onEnded { value in
                                        element.position = CGPoint(
                                            x: (center.x + value.translation.width) / canvasSize.width,
                                            y: (center.y + value.translation.height) / canvasSize.height
                                        )
                                    },
                                MagnifyGesture()
                                    .updating($pinchScale) { value, state, _ in state = value.magnification }
                                    .onEnded { value in
                                        element.scale = max(0.1, element.scale * value.magnification)
                                    }
                            ),
                            RotateGesture()
                                .updating($gestureRotation) { value, state, _ in
                                    state = value.rotation
                                }
                                .onChanged { value in
                                    if !rotationActivated && abs(value.rotation.degrees) > rotationThreshold {
                                        rotationActivated = true
                                    }
                                }
                                .onEnded { value in
                                    if rotationActivated {
                                        element.rotation += value.rotation.degrees
                                    }
                                    rotationActivated = false
                                }
                        )
                    )
                    .onTapGesture(perform: onTap)
            }
        }
    }
}
