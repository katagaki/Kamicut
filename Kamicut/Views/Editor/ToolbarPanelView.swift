import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar for the editor.
struct ToolbarPanelView: ToolbarContent {
    var editor: EditorState

    @State private var overlayPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker: Bool = false

    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ios26Toolbar
        } else {
            legacyToolbar
        }
    }

    // MARK: - iOS 26+ (native ToolbarItemGroup + ToolbarSpacer)

    @available(iOS 26, *)
    @ToolbarContentBuilder
    private var ios26Toolbar: some ToolbarContent {
        // Project + Layers
        ToolbarItemGroup(placement: .bottomBar) {
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
        }

        ToolbarSpacer(.flexible, placement: .bottomBar)

        // Add (+) Menu
        ToolbarItemGroup(placement: .bottomBar) {
            addMenu
        }

    }

    // MARK: - iOS 18 fallback (HStack)

    @ToolbarContentBuilder
    private var legacyToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                // Project
                Button {
                    editor.showProjectSettings = true
                } label: {
                    Label(String(localized: "Toolbar.Document"), systemImage: "doc.text")
                }

                // Layers
                Button {
                    editor.showLayerManager = true
                } label: {
                    Label(String(localized: "Toolbar.Layers"), systemImage: "square.3.layers.3d")
                }

                Spacer()
                    .frame(width: 16)

                addMenu

            }
        }
    }

    // MARK: - Shared Controls

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
