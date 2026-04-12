import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar for the editor, rendered via safeAreaInset
/// because DocumentGroup's navigation context does not reliably
/// support .bottomBar toolbar placement.
struct ToolbarPanelView: View {
    var editor: EditorState
    var transitionNamespace: Namespace.ID

    @State private var overlayPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker: Bool = false

    private let buttonSize: CGFloat = 52

    var body: some View {
        HStack(spacing: 16) {
            Button {
                editor.showLayerManager.toggle()
            } label: {
                Image(systemName: "square.3.layers.3d")

                    .frame(width: buttonSize, height: buttonSize)
            }
            .glassEffect(.regular.interactive(), in: .circle)
            .matchedTransitionSource(id: "layerManager", in: transitionNamespace)

            Spacer()

            addMenu
        }
        .imageScale(.large)
        .tint(.primary)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Add Menu

    private var addMenu: some View {
        Menu {
            Button {
                showPhotoPicker = true
            } label: {
                Label(String(localized: "Toolbar.Add.Image"), systemImage: "photo.stack")
            }
            Button {
                _ = editor.addTextElement()
            } label: {
                Label(String(localized: "Toolbar.Add.Text"), systemImage: "textformat")
            }
            Menu {
                ForEach(ShapeKind.allCases) { kind in
                    Button {
                        _ = editor.addShapeElement(kind)
                    } label: {
                        Label(kind.localizedName, systemImage: kind.systemImage)
                    }
                }
            } label: {
                Label(String(localized: "Toolbar.Add.Shape"), systemImage: "square.on.circle")
            }
            Button {
                editor.showSquiggleEditor = true
            } label: {
                Label(String(localized: "Toolbar.Add.Squiggle"), systemImage: "scribble.variable")
            }
        } label: {
            Image(systemName: "plus")
                .tint(.primary)
                .frame(width: buttonSize, height: buttonSize)
        }
        .glassEffect(.regular.tint(.accentColor).interactive(), in: .circle)
        .photosPicker(isPresented: $showPhotoPicker, selection: $overlayPickerItem, matching: .images)
        .onChange(of: overlayPickerItem) { _, item in
            Task { await loadOverlayImage(item: item) }
        }
    }

    // MARK: - Helpers

    private func loadOverlayImage(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        editor.addOverlayImage(image)
    }
}
