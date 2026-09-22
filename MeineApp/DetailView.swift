import SwiftUI

struct DetailView: View {
    @EnvironmentObject private var model: AppModel
    let item: CatalogItem
    let loaded: LoadedSource
    @State private var showPlayer = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(item.title).font(.largeTitle.bold())
                Text(credit).foregroundStyle(.secondary)
                if let summary = item.summary {
                    Text(summary)
                }
                if item.playableMedia != nil || !item.chapters.isEmpty {
                    Button(playTitle) { showPlayer = true }
                        .buttonStyle(.borderedProminent)
                } else {
                    Text("Mục này chưa có file media trong catalog.")
                        .foregroundStyle(.secondary)
                }
                Button("Thêm vào thư viện") {
                    model.addToLibrary(item, sourceID: loaded.manifest.id)
                }
                .buttonStyle(.bordered)
                if item.kind == .track || item.kind == .shortFilm || item.kind == .book {
                    Button("Thêm vào danh sách riêng") { addList() }
                        .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(model.palette.background)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPlayer) {
            player
        }
    }

    @ViewBuilder
    private var player: some View {
        switch item.kind {
        case .track:
            MusicPlayerView(item: item, root: loaded.root)
        case .movie, .shortFilm:
            VideoPlayerScreen(item: item, root: loaded.root)
        case .clip:
            ClipFeedView(loaded: loaded, feed: item.feed ?? "for-you", startRef: item.ref)
        case .comic:
            ComicReaderView(item: item, root: loaded.root)
        case .book:
            TextReaderView(item: item, root: loaded.root)
        case .album:
            Text("Album nguồn chỉ là gợi ý. Danh sách của bạn nằm trong Thư viện.")
                .padding()
        }
    }

    private var playTitle: String {
        switch item.kind {
        case .book: return "Đọc"
        case .comic: return "Đọc tranh"
        case .track: return "Nghe"
        default: return "Phát"
        }
    }

    private var credit: String {
        if !item.artists.isEmpty { return item.artists.joined(separator: ", ") }
        if !item.authors.isEmpty { return item.authors.joined(separator: ", ") }
        return item.creator ?? item.kind.rawValue
    }

    private func addList() {
        let list = UserList(
            id: UUID(),
            title: item.title,
            kind: item.kind.rawValue,
            isPublic: false,
            refs: [item.ref]
        )
        model.lists.insert(list, at: 0)
        model.saveLists()
    }
}

enum MediaURL {
    static func resolve(_ href: String, root: URL) -> URL? {
        if Href.isAbsoluteHTTP(href) { return URL(string: href) }
        guard Href.isSafeRelative(href) else { return nil }
        return root.appendingPathComponent(href)
    }
}
