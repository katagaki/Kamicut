import SwiftUI
import SwiftData

// MARK: - Projects List View

struct ProjectsListView: View {
    @Query(sort: \SavedCut.name) private var savedCuts: [SavedCut]
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()
    @State private var showNewProjectAlert = false
    @State private var newCircleName = ""
    @State private var showRenameAlert = false
    @State private var renamingCut: SavedCut?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if savedCuts.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "Projects.Empty"), systemImage: "doc.richtext")
                    } description: {
                        Text(String(localized: "Projects.EmptyDescription"))
                    }
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                            ],
                            spacing: 16
                        ) {
                            ForEach(savedCuts) { cut in
                                NavigationLink(value: cut) {
                                    ProjectCardView(cut: cut)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        renamingCut = cut
                                        renameText = cut.name
                                        showRenameAlert = true
                                    } label: {
                                        Label(String(localized: "Projects.Rename"), systemImage: "pencil")
                                    }
                                    Button {
                                        duplicateCut(cut)
                                    } label: {
                                        Label(String(localized: "Projects.Duplicate"), systemImage: "plus.square.on.square")
                                    }
                                    Button(role: .destructive) {
                                        deleteCut(cut)
                                    } label: {
                                        Label("Common.Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .animation(.smooth.speed(2.0), value: savedCuts.map(\.name))
                        .padding()
                    }
                }
            }
            .background {
                LinearGradient(
                    colors: [Color("BackgroundGradientTopColor"), Color("BackgroundGradientBottomColor")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle(String(localized: "Projects.Title"))
            .navigationDestination(for: SavedCut.self) { cut in
                EditorDestination(savedCut: cut)
            }
            .navigationDestination(for: NewProjectTag.self) { tag in
                EditorDestination(savedCut: nil, circleName: tag.circleName)
            }
            .alert(String(localized: "Projects.NewProject"), isPresented: $showNewProjectAlert) {
                TextField(String(localized: "Document.CircleName"), text: $newCircleName)
                Button(String(localized: "Common.Cancel"), role: .cancel) {}
                Button(String(localized: "Common.Create")) {
                    path.append(NewProjectTag(circleName: newCircleName))
                }
                .disabled(newCircleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text(String(localized: "Projects.EnterCircleName"))
            }
            .alert(String(localized: "Projects.Rename"), isPresented: $showRenameAlert) {
                TextField(String(localized: "Document.CircleName"), text: $renameText)
                Button(String(localized: "Common.Cancel"), role: .cancel) {}
                Button(String(localized: "Common.Save")) {
                    renameCut()
                }
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Link(destination: URL(string: "https://github.com/katagaki/Kamicut")!) {
                            Label(
                                String(localized: "App.SourceCode"),
                                systemImage: "chevron.left.forwardslash.chevron.right"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        newCircleName = ""
                        showNewProjectAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                }
            }
        }
    }

    // MARK: - Actions

    private func renameCut() {
        guard let cut = renamingCut else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cut.name = trimmed
        if var document = try? cut.loadDocument() {
            document.circleName = trimmed
            try? cut.updateDocument(document)
        }
        renamingCut = nil
    }

    private func deleteCut(_ cut: SavedCut) {
        modelContext.delete(cut)
    }

    private func duplicateCut(_ cut: SavedCut) {
        do {
            let document = try cut.loadDocument()
            let duplicate = try SavedCut(
                name: String(localized: "Projects.DuplicateSuffix \(cut.name)"),
                document: document
            )
            duplicate.thumbnailData = cut.thumbnailData
            modelContext.insert(duplicate)
        } catch {
            // Encoding/decoding error — unlikely
        }
    }
}
