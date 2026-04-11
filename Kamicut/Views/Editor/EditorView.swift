import SwiftUI

// MARK: - Editor View

struct EditorView: View {
    @Bindable var editor: EditorState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var sheetDetent: PresentationDetent = .height(300)
    @State private var exportSheetDetent: PresentationDetent = .large
    @State private var zoomResetToken: Int = 0
    @Namespace private var transitionNamespace

    private var useInspector: Bool { horizontalSizeClass == .regular }

    private var isAnySheetActive: Bool {
        editor.showTemplatePicker || editor.showProjectSettings || editor.showExportSheet ||
        editor.showLayerManager ||
        editor.selectedTextID != nil || editor.selectedShapeID != nil || editor.selectedImageID != nil
    }

    var body: some View {
        canvasPreview
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.editor)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        editor.showExportSheet = true
                    } label: {
                        Label(String(localized: "Toolbar.Export"), systemImage: "square.and.arrow.up")
                    }
                    if useInspector {
                        Button {
                            editor.showTemplatePicker = true
                        } label: {
                            Label(String(localized: "Toolbar.Template"), systemImage: "rectangle.on.rectangle")
                        }
                        Button {
                            editor.showProjectSettings = true
                        } label: {
                            Label(String(localized: "Toolbar.Document"), systemImage: "doc.badge.gearshape")
                        }
                        Menu {
                            Link(destination: URL(string: "https://github.com/katagaki/Kamicut")!) {
                                Label(String(localized: "More.SourceCode"), systemImage: "curlybraces")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    } else {
                        Menu {
                            Button {
                                editor.showTemplatePicker = true
                            } label: {
                                Label(String(localized: "More.Template"), systemImage: "rectangle.on.rectangle")
                            }
                            Button {
                                editor.showProjectSettings = true
                            } label: {
                                Label(String(localized: "More.DocumentSettings"), systemImage: "doc.badge.gearshape")
                            }
                            Divider()
                            Link(destination: URL(string: "https://github.com/katagaki/Kamicut")!) {
                                Label(String(localized: "More.SourceCode"), systemImage: "curlybraces")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ToolbarPanelView(editor: editor, transitionNamespace: transitionNamespace)
            }
            .onChange(of: isAnySheetActive) { _, isActive in
                if isActive {
                    sheetDetent = .height(300)
                }
            }
            .onChange(of: editor.selectedTextID) { _, _ in
                if editor.selectedTextID != nil { sheetDetent = .height(300) }
            }
            .onChange(of: editor.selectedShapeID) { _, _ in
                if editor.selectedShapeID != nil { sheetDetent = .height(300) }
            }
            .onChange(of: editor.selectedImageID) { _, _ in
                if editor.selectedImageID != nil { sheetDetent = .height(300) }
            }
            .onChange(of: editor.document.template.canvasSize) {
                zoomResetToken += 1
            }
            // Sheets (inspector on iPad, sheet on iPhone)
            .adaptiveSheet(isPresented: $editor.showTemplatePicker, useInspector: useInspector) {
                TemplatePickerView(editor: editor)
                    .presentationDetents([.large])
                    .presentationContentInteraction(.scrolls)
            }
            .adaptiveSheet(isPresented: $editor.showProjectSettings, useInspector: useInspector) {
                ProjectSettingsView(editor: editor)
                    .presentationDetents([.height(300), .large], selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled()
            }
            .adaptiveSheet(isPresented: $editor.showExportSheet, useInspector: useInspector) {
                ExportSheetView(editor: editor)
                    .presentationDetents([.medium, .large], selection: $exportSheetDetent)
                    .presentationContentInteraction(.scrolls)
            }
            .adaptiveSheet(isPresented: $editor.showLayerManager, useInspector: useInspector) {
                LayerManagerView(editor: editor)
                    .presentationDetents([.height(300), .large], selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled()
                    .navigationTransition(.zoom(sourceID: "layerManager", in: transitionNamespace))
            }
            .adaptiveSheet(isPresented: Binding(
                get: {
                    editor.selectedTextID != nil
                    || editor.selectedShapeID != nil
                    || editor.selectedImageID != nil
                },
                set: {
                    if !$0 {
                        editor.selectedTextID = nil
                        editor.selectedShapeID = nil
                        editor.selectedImageID = nil
                    }
                }
            ), useInspector: useInspector) {
                SelectedElementInspectorView(editor: editor)
                    .presentationDetents([.height(100), .height(300), .large], selection: $sheetDetent)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled()
            }
            .fullScreenCover(isPresented: $editor.showSquiggleEditor) {
                SquiggleEditorView(editor: editor)
            }
    }

    // MARK: - Canvas Preview

    @ViewBuilder
    private var canvasPreview: some View {
        let template = editor.document.template

        ZStack {
            Color(UIColor.secondarySystemBackground)

            ZoomableScrollView(additionalBottomInset: 60,
                               focalSize: template.canvasSize,
                               zoomResetToken: zoomResetToken) {
                Color.clear
                    .frame(width: template.canvasSize.width * 3,
                           height: template.canvasSize.height * 3)
                    .overlay {
                        EditorCanvasView(editor: editor)
                            .frame(width: template.canvasSize.width,
                                   height: template.canvasSize.height)
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(16)
            }
        }
    }
}

// MARK: - Adaptive Sheet / Inspector

private extension View {
    @ViewBuilder
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        useInspector: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if useInspector {
            self.inspector(isPresented: isPresented) {
                content()
                    .inspectorColumnWidth(min: 320, ideal: 380, max: 480)
            }
        } else {
            self.sheet(isPresented: isPresented) {
                content()
            }
        }
    }
}
