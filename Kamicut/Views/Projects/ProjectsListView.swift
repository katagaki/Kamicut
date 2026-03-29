import SwiftUI
import SwiftData

// MARK: - Projects List View

struct ProjectsListView: View {
    @Query(sort: \SavedCut.updatedAt, order: .reverse) private var savedCuts: [SavedCut]
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()

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
                    List {
                        ForEach(savedCuts) { cut in
                            NavigationLink(value: cut) {
                                ProjectRowView(cut: cut)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteCut(cut)
                                } label: {
                                    Label("Common.Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    duplicateCut(cut)
                                } label: {
                                    Label(String(localized: "Projects.Duplicate"), systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
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
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(String(localized: "App.Name"))
            .navigationDestination(for: SavedCut.self) { cut in
                EditorDestination(savedCut: cut)
            }
            .navigationDestination(for: NewProjectTag.self) { _ in
                EditorDestination(savedCut: nil)
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
                        path.append(NewProjectTag())
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
