import SwiftUI

struct TextElementView: View {
    @Binding var element: TextElement
    let canvasSize: CGSize
    let isSelected: Bool
    let onTap: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero

    var body: some View {
        let center = CGPoint(
            x: element.position.x * canvasSize.width,
            y: element.position.y * canvasSize.height
        )

        let radians = element.rotation * .pi / 180
        let boundingW = abs(textSize.width * cos(radians)) + abs(textSize.height * sin(radians))
        let boundingH = abs(textSize.width * sin(radians)) + abs(textSize.height * cos(radians))

        ZStack {
            styledText
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: TextSizeKey.self, value: geo.size)
                    }
                )
                .onPreferenceChange(TextSizeKey.self) { textSize = $0 }
                .rotationEffect(.degrees(element.rotation))

            if isSelected {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.blue.opacity(0.7), lineWidth: 1)
                    .frame(width: boundingW + 8, height: boundingH + 8)
            }
        }
        .position(
            x: center.x + dragOffset.width,
            y: center.y + dragOffset.height
        )
        .gesture(
            isSelected
                ? DragGesture()
                    .updating($dragOffset) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        element.position = CGPoint(
                            x: (center.x + value.translation.width) / canvasSize.width,
                            y: (center.y + value.translation.height) / canvasSize.height
                        )
                    }
                : nil
        )
        .onTapGesture(perform: onTap)
    }

    private var styledText: some View {
        CanvasTextView(element: element)
    }
}

private struct TextSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
