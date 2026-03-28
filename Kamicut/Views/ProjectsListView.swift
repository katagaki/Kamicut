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
                            Label(String(localized: "App.SourceCode"), systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
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

// MARK: - Project Row

private struct ProjectRowView: View {
    let cut: SavedCut

    var body: some View {
        HStack(spacing: 12) {
            if let thumbData = cut.thumbnailData, let img = UIImage(data: thumbData) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ContentView(vm: vm)
            .onAppear {
                guard let savedCut, vm.currentSavedCutID == nil else { return }
                try? vm.loadSavedCut(savedCut)
            }
            .onDisappear {
                autoSave()
            }
    }

    private func autoSave() {
        // Generate thumbnail
        let renderer = CircleCutRenderer()
        let thumbnailImage: UIImage? = {
            // Render synchronously on main thread for onDisappear
            let semaphore = DispatchSemaphore(value: 0)
            var result: UIImage?
            Task { @MainActor in
                result = await renderer.render(document: vm.document)
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }()
        let thumbnailData = thumbnailImage?
            .preparingThumbnail(of: CGSize(width: 112, height: 112))?
            .jpegData(compressionQuality: 0.7)

        do {
            if let existingID = vm.currentSavedCutID {
                let predicate = #Predicate<SavedCut> { $0.id == existingID }
                let descriptor = FetchDescriptor<SavedCut>(predicate: predicate)
                if let existing = try modelContext.fetch(descriptor).first {
                    try existing.updateDocument(vm.document)
                    existing.thumbnailData = thumbnailData
                }
            } else if !vm.document.layers.isEmpty || vm.document.backgroundImage != nil {
                let name = vm.currentSavedCutName.isEmpty
                    ? vm.document.template.localizedDisplayName
                    : vm.currentSavedCutName
                let newCut = try SavedCut(name: name, document: vm.document)
                newCut.thumbnailData = thumbnailData
                modelContext.insert(newCut)
                vm.currentSavedCutID = newCut.id
                vm.currentSavedCutName = newCut.name
            }
        } catch {
            // Encoding error — unlikely
        }
    }
}
