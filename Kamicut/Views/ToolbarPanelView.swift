import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar with all editing actions.
struct ToolbarPanelView: ToolbarContent {
    var vm: EditorState

    @State private var bgPickerItem: PhotosPickerItem? = nil
    @State private var overlayPickerItem: PhotosPickerItem? = nil

    var body: some ToolbarContent {
        // Template configuration group
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showTemplatePicker = true
            } label: {
                Label(String(localized: "Toolbar.Template"), systemImage: "rectangle.on.rectangle")
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.document.bleedOption = vm.bleedOption == .full ? .none : .full
            } label: {
                Label(
                    vm.bleedOption == .full ? String(localized: "Toolbar.BleedOn") : String(localized: "Toolbar.BleedOff"),
                    systemImage: vm.bleedOption == .full ? "rectangle.inset.filled" : "rectangle"
                )
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showSpaceNumberEditor = true
            } label: {
                Label(String(localized: "Toolbar.SpaceNumber"), systemImage: "number.square")
            }
        }

        ToolbarSpacer(.fixed)

        // Content addition group
        ToolbarItem(placement: .bottomBar) {
            PhotosPicker(selection: $bgPickerItem, matching: .images) {
                Label(String(localized: "Toolbar.Background"), systemImage: "photo")
            }
            .onChange(of: bgPickerItem) { _, item in
                Task { await loadImage(item: item, asBackground: true) }
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .bottomBar) {
            PhotosPicker(selection: $overlayPickerItem, matching: .images) {
                Label(String(localized: "Toolbar.Image"), systemImage: "photo.stack")
            }
            .onChange(of: overlayPickerItem) { _, item in
                Task { await loadImage(item: item, asBackground: false) }
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .bottomBar) {
            Button {
                let _ = vm.addTextElement()
            } label: {
                Label(String(localized: "Toolbar.Text"), systemImage: "textformat")
            }
        }

        // Flexible spacer — pushes layers/export to the trailing edge
        ToolbarSpacer(.flexible)

        // Management group
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showLayerManager = true
            } label: {
                Label(String(localized: "Toolbar.Layers"), systemImage: "square.3.layers.3d")
            }
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showExportSheet = true
            } label: {
                Label(String(localized: "Toolbar.Export"), systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Helpers

    private func loadImage(item: PhotosPickerItem?, asBackground: Bool) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        if asBackground {
            vm.setBackgroundImage(image)
        } else {
            vm.addOverlayImage(image)
        }
    }
}
