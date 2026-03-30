import SwiftUI

struct MoreView: View {

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Kamicut")!) {
                        HStack {
                            Text(String(localized: "More.SourceCode"))
                            Spacer()
                            Text("katagaki/Kamicut")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle(String(localized: "More.Title"))
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
    }
}
