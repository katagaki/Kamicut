import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar with all editing actions.
struct ToolbarPanelView: View {
    var vm: EditorState

    // Photo picker state
    @State private var bgPickerItem: PhotosPickerItem? = nil
    @State private var overlayPickerItem: PhotosPickerItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Template setup actions
            HStack(spacing: 0) {
                toolbarButton(icon: "rectangle.on.rectangle", label: String(localized: "Toolbar.Template")) {
                    vm.showTemplatePicker = true
                }

                Divider().frame(height: 28)

                PhotosPicker(selection: $bgPickerItem, matching: .images) {
                    toolbarButtonLabel(icon: "photo", label: String(localized: "Toolbar.Background"))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .onChange(of: bgPickerItem) { _, item in
                    Task { await loadImage(item: item, asBackground: true) }
                }

                Divider().frame(height: 28)

                toolbarButton(
                    icon: vm.bleedOption == .full ? "rectangle.inset.filled" : "rectangle",
                    label: vm.bleedOption == .full ? String(localized: "Toolbar.BleedOn") : String(localized: "Toolbar.BleedOff")
                ) {
                    vm.document.bleedOption = vm.bleedOption == .full ? .none : .full
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "number.square", label: String(localized: "Toolbar.SpaceNumber")) {
                    vm.showSpaceNumberEditor = true
                }
            }

            Divider()

            // Row 2: Content and management actions
            HStack(spacing: 0) {
                PhotosPicker(selection: $overlayPickerItem, matching: .images) {
                    toolbarButtonLabel(icon: "photo.stack", label: String(localized: "Toolbar.Image"))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .onChange(of: overlayPickerItem) { _, item in
                    Task { await loadImage(item: item, asBackground: false) }
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "textformat", label: String(localized: "Toolbar.Text")) {
                    let _ = vm.addTextElement()
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "square.3.layers.3d", label: String(localized: "Toolbar.Layers")) {
                    vm.showLayerManager = true
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "square.and.arrow.up", label: String(localized: "Toolbar.Export")) {
                    vm.showExportSheet = true
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func toolbarButtonLabel(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(height: 24, alignment: .center)
            Text(label)
                .font(.system(size: 10))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .contentShape(Rectangle())
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolbarButtonLabel(icon: icon, label: label)
        }
        .buttonStyle(.plain)
    }

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
