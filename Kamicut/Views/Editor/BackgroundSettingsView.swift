import SwiftUI
import PhotosUI

// MARK: - Background Settings View

struct BackgroundSettingsView: View {
    @Bindable var vm: EditorState

    @Environment(\.dismiss) private var dismiss
    @State private var backgroundPickerItem: PhotosPickerItem?
    @State private var backgroundColor: Color = .white
    @State private var hasBackgroundColor: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                // Color
                Section(String(localized: "Toolbar.Background.ColorHeader")) {
                    Toggle(String(localized: "Toolbar.Background.SetColor"), isOn: $hasBackgroundColor.animation(.smooth.speed(2.0)))
                        .onChange(of: hasBackgroundColor) { _, enabled in
                            if enabled {
                                vm.setBackgroundColor(backgroundColor)
                            } else {
                                vm.removeBackgroundColor()
                            }
                        }
                    if hasBackgroundColor {
                        ColorPicker(String(localized: "Common.Color"), selection: $backgroundColor)
                            .onChange(of: backgroundColor) { _, newColor in
                                vm.setBackgroundColor(newColor)
                            }
                    }
                }

                // Image
                Section(String(localized: "Toolbar.Background.ImageHeader")) {
                    PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                        Label(String(localized: "Toolbar.Background.SelectImage"), systemImage: "photo")
                    }
                    .onChange(of: backgroundPickerItem) { _, item in
                        Task { await loadBackgroundImage(item: item) }
                    }
                    if vm.document.backgroundImage != nil {
                        Button(role: .destructive) {
                            vm.removeBackgroundImage()
                        } label: {
                            Label(String(localized: "Common.Delete"), systemImage: "trash")
                        }
                    }
                }

                // Bleed
                Section(String(localized: "Toolbar.Background.Bleed")) {
                    Picker(String(localized: "Toolbar.Background.Bleed"), selection: $vm.document.bleedOption) {
                        ForEach(BleedOption.allCases, id: \.self) { option in
                            Text(option.localizedName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(String(localized: "Toolbar.Background"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .close) { dismiss() }
                    } else {
                        Button(String(localized: "Common.Close")) { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            if let existing = vm.document.backgroundColor {
                hasBackgroundColor = true
                backgroundColor = existing.color
            }
        }
    }

    // MARK: - Helpers

    private func loadBackgroundImage(item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        vm.setBackgroundImage(image)
    }
}
