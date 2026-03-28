import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar for the editor.
struct ToolbarPanelView: ToolbarContent {
    var vm: EditorState

    @State private var overlayPickerItem: PhotosPickerItem? = nil
    @State private var showPhotoPicker: Bool = false

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                // Layers
                Button {
                    vm.showLayerManager = true
                } label: {
                    Label(String(localized: "Toolbar.Layers"), systemImage: "square.3.layers.3d")
                }

                // Background
                Button {
                    vm.showBackgroundSettings = true
                } label: {
                    Label(String(localized: "Toolbar.Background"), systemImage: "photo.artframe")
                }

                Spacer()
                    .frame(width: 16)

                // Add (+) Menu
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label(String(localized: "Toolbar.Add.Image"), systemImage: "photo.stack")
                    }
                    Button {
                        let _ = vm.addTextElement()
                    } label: {
                        Label(String(localized: "Toolbar.Add.Text"), systemImage: "textformat")
                    }
                    Button {
                        // TODO: Shape support
                    } label: {
                        Label(String(localized: "Toolbar.Add.Shape"), systemImage: "square.on.circle")
                    }
                    .disabled(true)
                } label: {
                    Label(String(localized: "Toolbar.Add"), systemImage: "plus")
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $overlayPickerItem, matching: .images)
                .onChange(of: overlayPickerItem) { _, item in
                    Task { await loadOverlayImage(item: item) }
                }

                Spacer()

                // Export
                Button {
                    vm.showExportSheet = true
                } label: {
                    Label(String(localized: "Toolbar.Export"), systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadOverlayImage(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        vm.addOverlayImage(image)
    }
}
