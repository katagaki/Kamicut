import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar with all editing actions.
struct ToolbarPanelView: ToolbarContent {
    var vm: EditorState

    @State private var bgPickerItem: PhotosPickerItem? = nil
    @State private var overlayPickerItem: PhotosPickerItem? = nil

    private var bleedBinding: Binding<Bool> {
        Binding(
            get: { vm.bleedOption == .full },
            set: { vm.document.bleedOption = $0 ? .full : .none }
        )
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { vm.document.backgroundColor?.color ?? .white },
            set: { vm.document.backgroundColor = CodableColor(color: $0) }
        )
    }

    var body: some ToolbarContent {
        // Template
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showTemplatePicker = true
            } label: {
                Label(String(localized: "Toolbar.Template"), systemImage: "rectangle.on.rectangle")
            }
        }
        ToolbarSpacer(.fixed)

        // Space Number
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showSpaceNumberEditor = true
            } label: {
                Label(String(localized: "Toolbar.SpaceNumber"), systemImage: "number.square")
            }
        }
        ToolbarSpacer(.fixed)

        // Background Menu
        ToolbarItem(placement: .bottomBar) {
            Menu {
                Section(String(localized: "Toolbar.Background.ImageHeader")) {
                    PhotosPicker(selection: $bgPickerItem, matching: .images) {
                        Label(String(localized: "Toolbar.Background.SelectImage"), systemImage: "photo.on.rectangle")
                    }
                    Toggle(isOn: bleedBinding) {
                        Label(String(localized: "Toolbar.Background.Bleed"), systemImage: "rectangle.inset.filled")
                    }
                }

                Section(String(localized: "Toolbar.Background.ColorHeader")) {
                    ColorPicker(selection: backgroundColorBinding, supportsOpacity: false) {
                        Label(String(localized: "Toolbar.Background.SetColor"), systemImage: "paintbrush.fill")
                    }
                    Button(role: .destructive) {
                        vm.removeBackgroundColor()
                    } label: {
                        Label(String(localized: "Toolbar.Background.UnsetColor"), systemImage: "xmark.circle")
                    }
                }
            } label: {
                Label(String(localized: "Toolbar.Background"), systemImage: "photo")
            }
            .onChange(of: bgPickerItem) { _, item in
                Task { await loadImage(item: item, asBackground: true) }
            }
        }
        ToolbarSpacer(.fixed)

        // Add (+) Menu
        ToolbarItem(placement: .bottomBar) {
            Menu {
                PhotosPicker(selection: $overlayPickerItem, matching: .images) {
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
            .onChange(of: overlayPickerItem) { _, item in
                Task { await loadImage(item: item, asBackground: false) }
            }
        }

        // Flexible spacer — pushes layers/export to the trailing edge
        ToolbarSpacer(.flexible)

        // Layers
        ToolbarItem(placement: .bottomBar) {
            Button {
                vm.showLayerManager = true
            } label: {
                Label(String(localized: "Toolbar.Layers"), systemImage: "square.3.layers.3d")
            }
        }
        ToolbarSpacer(.fixed)

        // Export
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
