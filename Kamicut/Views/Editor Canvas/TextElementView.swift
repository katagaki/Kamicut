import SwiftUI

struct TextElementView: View {
    @Binding var element: TextElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )

        styledText
            .rotationEffect(.degrees(element.rotation))
            .overlay(
                isSelected
                    ? RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                        .padding(-4)
                    : nil
            )
            .position(
                x: center.x + dragOffset.width,
                y: center.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        element.position = CGPoint(
                            x: (center.x + value.translation.width) / canvasSize.width,
                            y: (center.y + value.translation.height) / canvasSize.height
                        )
                    }
            )
            .onTapGesture(perform: onTap)
    }

    private var styledText: some View {
        CanvasTextView(element: element)
    }
}
