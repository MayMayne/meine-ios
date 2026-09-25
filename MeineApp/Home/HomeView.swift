import SwiftUI

struct HomeView: View {
    @Environment(LibraryStore.self) private var library

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if library.visibleSources.isEmpty {
                        ContentUnavailableView(
                            "Nhà đang trống",
                            systemImage: "sparkles",
                            description: Text("Thêm thư mục ở tab Thư viện. Nguồn đang khoá không hiện ở đây.")
                        )
                        .padding(.top, 40)
                    } else {
                        ForEach(library.visibleSources) { source in
                            SourceStrip(source: source, items: library.contents(of: source))
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Palette.ivory)
            .navigationTitle("Meine")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hôm nay")
                .font(.title2.weight(.semibold))
            Text("Phim, nhạc, tranh, chữ — từ thư mục của bạn.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

private struct SourceStrip: View {
    let source: SourceRecord
    let items: [LocalMedia]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(source.title)
                .font(.headline)
                .padding(.horizontal, 20)
            if items.isEmpty {
                Text("Không nhận ra tệp nào trong thư mục này.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items.prefix(12)) { item in
                            MediaCard(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct MediaCard: View {
    let item: LocalMedia

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Palette.pastel.opacity(0.55))
                .frame(width: 132, height: 176)
                .overlay {
                    Image(systemName: symbol)
                        .font(.title)
                        .foregroundStyle(Palette.accent)
                }
            Text(item.title)
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .frame(width: 132, alignment: .leading)
            Text(item.kind.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var symbol: String {
        switch item.kind {
        case .video, .short: "film"
        case .music: "music.note"
        case .comic: "book.closed"
        case .novel: "text.book.closed"
        case .unknown: "doc"
        }
    }
}
