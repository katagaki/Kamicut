import SwiftUI

// MARK: - Editor View

struct EditorView: View {
    @Bindable var editor: EditorState
    @State private var canvasScale: CGFloat = 1.0
    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var sheetDetent: PresentationDetent = .height(300)
    @State private var exportSheetDetent: PresentationDetent = .large
    @State private var canvasBottomPadding: CGFloat = 0

    private var isAnySheetActive: Bool {
        editor.showTemplatePicker || editor.showProjectSettings || editor.showExportSheet ||
        editor.showLayerManager || editor.showBackgroundSettings ||
        editor.selectedTextID != nil || editor.selectedShapeID != nil
    }

    var body: some View {
        ZStack {
            // Canvas background spans entire screen
            canvasPreview
                .ignoresSafeArea()

            // Element toolbar (shows when element selected)
            GeometryReader { geo in
                VStack(alignment: .center) {
                    Spacer()
                    ElementToolbarView(editor: editor)
                        .animation(.smooth.speed(2.0), value: editor.selectedImageID)
                        .animation(.smooth.speed(2.0), value: editor.selectedTextID)
                        .animation(.smooth.speed(2.0), value: editor.selectedShapeID)
                        .padding(.bottom, canvasBottomPadding > 0
                                 ? canvasBottomPadding - geo.safeAreaInsets.bottom / 2 + 8
                            : 8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle(String(localized: "App.Name"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    editor.showTemplatePicker = true
                } label: {
                    Image(systemName: "rectangle.on.rectangle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editor.showExportSheet = true
                } label: {
                    Label(String(localized: "Toolbar.Export"), systemImage: "square.and.arrow.up")
                }
            }
            ToolbarPanelView(editor: editor)
        }
        .onChange(of: sheetDetent) { _, newDetent in
            withAnimation(.spring(duration: 0.3)) {
                canvasBottomPadding = (isAnySheetActive && newDetent == .height(300)) ? 300 : 0
            }
        }
        .onChange(of: isAnySheetActive) { _, isActive in
            if isActive {
                sheetDetent = .height(300)
                withAnimation(.spring(duration: 0.3)) {
                    canvasBottomPadding = 300
                }
            } else {
                withAnimation(.spring(duration: 0.3)) {
                    canvasBottomPadding = 0
                }
            }
        }
        .onChange(of: editor.selectedTextID) { _, _ in
            if editor.selectedTextID != nil { sheetDetent = .height(300) }
        }
        .onChange(of: editor.selectedShapeID) { _, _ in
            if editor.selectedShapeID != nil { sheetDetent = .height(300) }
        }
        // Sheets
        .sheet(isPresented: $editor.showTemplatePicker) {
            TemplatePickerView(editor: editor)
                .presentationDetents([.large])
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $editor.showProjectSettings) {
            ProjectSettingsView(editor: editor)
                .presentationDetents([.height(300), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $editor.showExportSheet) {
            ExportSheetView(editor: editor)
                .presentationDetents([.medium, .large], selection: $exportSheetDetent)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $editor.showLayerManager) {
            LayerManagerView(editor: editor)
                .presentationDetents([.height(300), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $editor.showBackgroundSettings) {
            BackgroundSettingsView(editor: editor)
                .presentationDetents([.height(300), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: Binding(
            get: { editor.selectedTextID != nil || editor.selectedShapeID != nil },
            set: { if !$0 { editor.selectedTextID = nil; editor.selectedShapeID = nil } }
        )) {
            SelectedElementInspectorView(editor: editor)
                .presentationDetents([.height(300), .large], selection: $sheetDetent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.scrolls)
        }
        .sheet(isPresented: $editor.showSavedCutsList) {
            SavedCutsListView(editor: editor)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $editor.showSquiggleEditor) {
            SquiggleEditorView(editor: editor)
        }
    }

    // MARK: - Canvas Preview

    @ViewBuilder
    private var canvasPreview: some View {
        let template = editor.document.template

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
                    EditorCanvasView(editor: editor)
                        .scaleEffect(effectiveScale)
                        .frame(width: max(scaledW, previewGeo.size.width),
                               height: max(scaledH, previewGeo.size.height))
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .safeAreaPadding(.bottom, canvasBottomPadding)
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
