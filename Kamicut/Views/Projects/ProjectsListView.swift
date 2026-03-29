import SwiftUI

// MARK: - Projects List View

struct ProjectsListView: View {
    @State private var storageManager = CutStorageManager.shared
    @State private var path = NavigationPath()
    @State private var showNewProjectAlert = false
    @State private var newCircleName = ""
    @State private var showRenameAlert = false
    @State private var renamingCut: CutListItem?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if storageManager.cuts.isEmpty {
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
                            ForEach(storageManager.cuts) { cut in
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
                        .animation(.smooth.speed(2.0), value: storageManager.cuts.map(\.name))
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
            .navigationDestination(for: CutListItem.self) { cut in
                EditorDestination(cutItem: cut)
            }
            .navigationDestination(for: NewProjectTag.self) { tag in
                EditorDestination(cutItem: nil, circleName: tag.circleName)
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
        try? storageManager.renameCut(at: cut.packageURL, newName: trimmed)
        storageManager.loadAllCuts()
        renamingCut = nil
    }

    private func deleteCut(_ cut: CutListItem) {
        storageManager.deleteCut(at: cut.packageURL)
    }

    private func duplicateCut(_ cut: CutListItem) {
        do {
            _ = try storageManager.duplicateCut(
                from: cut.packageURL,
                newName: String(localized: "Projects.DuplicateSuffix \(cut.name)")
            )
            storageManager.loadAllCuts()
        } catch {
            // Unlikely
        }
    }
}
