import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar for the editor, rendered as a regular view.
struct ToolbarPanelView: View {
    var editor: EditorState

    @State private var overlayPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker: Bool = false

    var body: some View {
        HStack {
            Button {
                editor.showProjectSettings = true
            } label: {
                Label(String(localized: "Toolbar.Document"), systemImage: "doc.text")
            }
            Button {
                editor.showLayerManager = true
            } label: {
                Label(String(localized: "Toolbar.Layers"), systemImage: "square.3.layers.3d")
            }

            Spacer()

            addMenu
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
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
            Label(String(localized: "Toolbar.Add"), systemImage: "plus")
        }
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
