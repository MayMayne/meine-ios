import SwiftUI
import UIKit

struct LoadedSource {
    var manifest: SourceManifest
    var page: HomePage
    var items: [String: CatalogItem]
    var root: URL
}

struct SourceHomeView: View {
    @EnvironmentObject private var model: AppModel
    let source: InstalledSource
    @State private var loaded: LoadedSource?
    @State private var error = ""
    @State private var password = ""
    @State private var locked = false

    var body: some View {
        Group {
            if locked {
                lock
            } else if let loaded {
                page(loaded)
            } else if !error.isEmpty {
                Text(error).padding()
            } else {
                ProgressView("Đang đọc nguồn")
            }
        }
        .background(model.palette.background)
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { open() }
    }

    private var lock: some View {
        VStack(spacing: 12) {
            Text("Nguồn này có mật khẩu")
            SecureField("Mật khẩu", text: $password)
                .textFieldStyle(.roundedBorder)
            Button("Mở") {
                if SourceLock.check(password, sourceID: source.id) {
                    model.unlocked.insert(source.id)
                    locked = false
                    open()
                } else {
                    error = "Sai mật khẩu"
                }
            }
            .buttonStyle(.borderedProminent)
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
        }
        .padding(24)
    }

    private func page(_ loaded: LoadedSource) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                if let title = loaded.page.title {
                    Text(title).font(.largeTitle.bold())
                        .padding(.horizontal, 16)
                }
                ForEach(loaded.page.sections) { section in
                    sectionView(section, loaded: loaded)
                }
            }
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection, loaded: LoadedSource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = section.title, section.type != .spacer {
                Text(title).font(.title3.bold()).padding(.horizontal, 16)
            }
            switch section.type {
            case .hero, .rail:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(section.items, id: \.ref) { card in
                            cardLink(card, loaded: loaded, wide: section.type == .hero)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            case .grid:
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: max(section.columns ?? 3, 2))
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(section.items, id: \.ref) { card in
                        cardLink(card, loaded: loaded, wide: false)
                    }
                }
                .padding(.horizontal, 16)
            case .list:
                ForEach(section.items, id: \.ref) { card in
                    cardLink(card, loaded: loaded, wide: true)
                        .padding(.horizontal, 16)
                }
            case .banner:
                Text(section.body ?? "")
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(model.palette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
            case .feed:
                NavigationLink {
                    ClipFeedView(loaded: loaded, feed: section.feed ?? "for-you")
                } label: {
                    Label(section.title ?? "Video ngắn", systemImage: "play.rectangle.on.rectangle")
                        .padding(.horizontal, 16)
                }
            case .continue, .genreChips, .spacer:
                EmptyView()
            }
        }
    }

    private func cardLink(_ card: HomeCard, loaded: LoadedSource, wide: Bool) -> some View {
        let item = loaded.items[card.ref]?.resolved(against: card) ?? CatalogItem.placeholder(card: card)
        return NavigationLink {
            DetailView(item: item, loaded: loaded)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                artwork(item.artwork, root: loaded.root)
                    .frame(width: wide ? 240 : 120, height: wide ? 136 : 168)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(item.title)
                    .font(.subheadline)
                    .lineLimit(2)
                    .frame(width: wide ? 240 : 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func artwork(_ href: String?, root: URL) -> some View {
        Group {
            if let href, Href.isSafeRelative(href),
               let image = UIImage(contentsOfFile: root.appendingPathComponent(href).path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                model.palette.card
                    .overlay(Image(systemName: "photo").foregroundStyle(model.palette.accent))
            }
        }
    }

    private func open() {
        if SourceLock.hasLock(sourceID: source.id), !model.unlocked.contains(source.id) {
            locked = true
            return
        }
        guard let root = model.root(for: source) else {
            error = "Không mở lại được thư mục. Thêm nguồn lần nữa."
            return
        }
        let scoped = root.startAccessingSecurityScopedResource()
        defer { if scoped { root.stopAccessingSecurityScopedResource() } }
        let report = SourceChecker.check(root: root)
        guard let manifest = report.manifest, let page = report.home else {
            error = report.issues.first?.message ?? "Nguồn lỗi"
            return
        }
        var items: [String: CatalogItem] = [:]
        if case .ref(let ref) = manifest.home,
           let data = try? Data(contentsOf: root.appendingPathComponent(ref)),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            items = CatalogParser.items(in: object)
        }
        loaded = LoadedSource(manifest: manifest, page: page, items: items, root: root)
    }
}
