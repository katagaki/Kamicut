import SwiftUI

// MARK: - Project Row

struct ProjectRowView: View {
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
