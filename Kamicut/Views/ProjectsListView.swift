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
                        }
                        .onDelete(perform: deleteCuts)
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
                            Label(String(localized: "App.SourceCode"), systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarSpacer(.flexible)
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

    private func deleteCuts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedCuts[index])
        }
    }
}

// MARK: - Project Row

private struct ProjectRowView: View {
    let cut: SavedCut

    var body: some View {
        HStack(spacing: 12) {
            if let thumbData = cut.thumbnailData, let img = UIImage(data: thumbData) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(cut.name)
                    .font(.headline)
                Text(cut.updatedAt, style: .relative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Navigation Tags

struct NewProjectTag: Hashable {}

// MARK: - Editor Destination

struct EditorDestination: View {
    let savedCut: SavedCut?
    @State private var vm = EditorState()

    var body: some View {
        ContentView(vm: vm)
            .onAppear {
                guard let savedCut, vm.currentSavedCutID == nil else { return }
                try? vm.loadSavedCut(savedCut)
            }
    }
}
