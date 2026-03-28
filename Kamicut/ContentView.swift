import SwiftUI

// MARK: - Content View (Main Editor)

struct ContentView: View {
    @Bindable var vm: EditorState
    @State private var canvasScale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var sheetDetent: PresentationDetent = .height(200)
    @State private var canvasBottomPadding: CGFloat = 0

    private var isAnySheetActive: Bool {
        vm.showTemplatePicker || vm.showExportSheet || vm.showSpaceNumberEditor ||
        vm.showLayerManager || vm.showBackgroundSettings || vm.selectedTextID != nil
    }

    var body: some View {
        ZStack {
            // Canvas background spans entire screen
            canvasPreview
                .ignoresSafeArea()

            // Element toolbar (shows when element selected)
            VStack {
                Spacer()
                ElementToolbarView(vm: vm)
                    .animation(.smooth.speed(2.0), value: vm.selectedImageID)
                    .animation(.smooth.speed(2.0), value: vm.selectedTextID)
                    .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle(String(localized: "App.Name"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    vm.showTemplatePicker = true
                } label: {
                    Label(String(localized: "Toolbar.Template"), systemImage: "rectangle.on.rectangle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.showSpaceNumberEditor = true
                } label: {
                    Label(String(localized: "Toolbar.SpaceNumber"), systemImage: "number.square")
                }
            }
            ToolbarPanelView(vm: vm)
        }
        .onChange(of: sheetDetent) { _, newDetent in
            withAnimation(.spring(duration: 0.3)) {
                canvasBottomPadding = (isAnySheetActive && newDetent == .height(200)) ? 200 : 0
            }
        }
        .onChange(of: isAnySheetActive) { _, isActive in
            if isActive {
                sheetDetent = .height(200)
                withAnimation(.spring(duration: 0.3)) {
                    canvasBottomPadding = 200
                }
            } else {
                withAnimation(.spring(duration: 0.3)) {
                    canvasBottomPadding = 0
                }
            }
        }
        // Sheets
        .sheet(isPresented: $vm.showTemplatePicker) {
            TemplatePickerView(vm: vm)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showExportSheet) {
            ExportSheetView(vm: vm)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showSpaceNumberEditor) {
            SpaceNumberEditorView(spaceNumber: $vm.document.spaceNumber)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showLayerManager) {
            LayerManagerView(vm: vm)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showBackgroundSettings) {
            BackgroundSettingsView(vm: vm)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: Binding(
            get: { vm.selectedTextID != nil },
            set: { if !$0 { vm.selectedTextID = nil } }
        )) {
            SelectedElementInspectorView(vm: vm)
                .presentationDetents([.height(200), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $vm.showSavedCutsList) {
            SavedCutsListView(vm: vm)
                .presentationDetents([.large])
        }
    }

    // MARK: - Canvas Preview

    @ViewBuilder
    private var canvasPreview: some View {
        let template = vm.document.template

        GeometryReader { previewGeo in
            let availableW = previewGeo.size.width - 32
            let availableH = previewGeo.size.height - 32 - canvasBottomPadding
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
                               height: max(scaledH, previewGeo.size.height - canvasBottomPadding))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(height: previewGeo.size.height - canvasBottomPadding)
                .offset(y: -canvasBottomPadding / 2)
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
