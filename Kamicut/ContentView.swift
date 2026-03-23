import SwiftUI

// MARK: - Content View (Main Editor)

struct ContentView: View {
    @State private var vm = EditorState()
    @State private var canvasScale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                // Canvas background spans entire screen
                canvasPreview
                    .ignoresSafeArea()

                // Bottom controls
                VStack(spacing: 8) {
                    Spacer()

                    // Element toolbar (shows when element selected)
                    ElementToolbarView(vm: vm)
                        .animation(.smooth.speed(2.0), value: vm.selectedImageID)
                        .animation(.smooth.speed(2.0), value: vm.selectedTextID)

                    // Toolbar
                    ToolbarPanelView(vm: vm)
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationTitle("Kamicut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.reset()
                    } label: {
                        Image(systemName: "doc.badge.plus")
                    }
                }
            }
        }
        // Sheets
        .sheet(isPresented: $vm.showTemplatePicker) {
            TemplatePickerView(vm: vm)
                .presentationDetents([.height(100), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showExportSheet) {
            ExportSheetView(vm: vm)
                .presentationDetents([.height(100), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showSpaceNumberEditor) {
            SpaceNumberEditorView(spaceNumber: $vm.document.spaceNumber)
                .presentationDetents([.height(100), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showLayerManager) {
            LayerManagerView(vm: vm)
                .presentationDetents([.height(100), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: Binding(
            get: { vm.selectedTextID != nil },
            set: { if !$0 { vm.selectedTextID = nil } }
        )) {
            SelectedElementInspectorView(vm: vm)
                .presentationDetents([.height(100), .medium, .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
    }

    // MARK: - Canvas Preview

    @ViewBuilder
    private var canvasPreview: some View {
        let template = vm.document.template

        GeometryReader { previewGeo in
            let availableW = previewGeo.size.width - 32
            let availableH = previewGeo.size.height - 32
            let fitScale = min(availableW / template.canvasSize.width,
                               availableH / template.canvasSize.height)
            let effectiveScale = fitScale * canvasScale * pinchScale

            let scaledW = template.canvasSize.width * effectiveScale
            let scaledH = template.canvasSize.height * effectiveScale

            ZStack {
                Color(UIColor.secondarySystemBackground)

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    EditorCanvasView(vm: vm)
                        .scaleEffect(effectiveScale)
                        .frame(width: max(scaledW, previewGeo.size.width),
                               height: max(scaledH, previewGeo.size.height))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .gesture(
                MagnifyGesture()
                    .updating($pinchScale) { value, state, _ in
                        state = value.magnification
                    }
                    .onEnded { value in
                        canvasScale = max(0.1, canvasScale * value.magnification)
                    }
            )
        }
    }
}

