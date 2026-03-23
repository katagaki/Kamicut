import SwiftUI
import PhotosUI

// MARK: - Toolbar Panel

/// Bottom toolbar with all editing actions.
struct ToolbarPanelView: View {
    var vm: EditorState

    // Photo picker state
    @State private var bgPickerItem: PhotosPickerItem? = nil
    @State private var overlayPickerItem: PhotosPickerItem? = nil

    private let buttonSize: CGFloat = 64

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                toolbarButton(icon: "rectangle.on.rectangle", label: "Template") {
                    vm.showTemplatePicker = true
                }

                Divider().frame(height: 28)

                PhotosPicker(selection: $bgPickerItem, matching: .images) {
                    toolbarButtonLabel(icon: "photo", label: "Background")
                }
                .buttonStyle(.plain)
                .frame(width: buttonSize, height: 48)
                .onChange(of: bgPickerItem) { _, item in
                    Task { await loadImage(item: item, asBackground: true) }
                }

                toolbarButton(
                    icon: vm.bleedOption == .full ? "rectangle.inset.filled" : "rectangle",
                    label: vm.bleedOption == .full ? "Bleed: On" : "Bleed: Off"
                ) {
                    vm.document.bleedOption = vm.bleedOption == .full ? .none : .full
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "number.square", label: "Space #") {
                    vm.showSpaceNumberEditor = true
                }

                Divider().frame(height: 28)

                PhotosPicker(selection: $overlayPickerItem, matching: .images) {
                    toolbarButtonLabel(icon: "photo.stack", label: "Image")
                }
                .buttonStyle(.plain)
                .frame(width: buttonSize, height: 48)
                .onChange(of: overlayPickerItem) { _, item in
                    Task { await loadImage(item: item, asBackground: false) }
                }

                toolbarButton(icon: "textformat", label: "Text") {
                    let _ = vm.addTextElement()
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "square.3.layers.3d", label: "Layers") {
                    vm.showLayerManager = true
                }

                Divider().frame(height: 28)

                toolbarButton(icon: "square.and.arrow.up", label: "Export") {
                    vm.showExportSheet = true
                }
            }
            .padding(.horizontal, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(height: 56)
        .clipShape(Capsule())
        .glassEffect(.regular.interactive(), in: .capsule)
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
        .frame(width: 64, height: 48)
        .contentShape(Rectangle())
    }

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolbarButtonLabel(icon: icon, label: label)
        }
        .buttonStyle(.plain)
        .frame(width: buttonSize, height: 48)
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
