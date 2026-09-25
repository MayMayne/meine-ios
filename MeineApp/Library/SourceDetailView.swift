import SwiftUI

struct SourceDetailView: View {
    @Environment(LibraryStore.self) private var library
    let source: SourceRecord
    @State private var unlocked = false

    private var current: SourceRecord {
        library.sources.first { $0.id == source.id } ?? source
    }

    var body: some View {
        Group {
            if current.isLocked && !unlocked {
                locked
            } else {
                contents
            }
        }
        .navigationTitle(current.isLocked && !unlocked ? "Đã khoá" : current.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(current.isLocked ? "Bỏ khoá" : "Khoá") {
                    library.setLocked(!current.isLocked, source: current)
                    unlocked = false
                }
            }
        }
    }

    private var locked: some View {
        ContentUnavailableView {
            Label("Nguồn đã khoá", systemImage: "lock.fill")
        } description: {
            Text("Tên và nội dung không hiện trên trang chủ cho đến khi mở khoá.")
        } actions: {
            Button("Mở bằng Face ID") { unlocked = true }
        }
    }

    private var contents: some View {
        let items = library.contents(of: current)
        return Group {
            if items.isEmpty {
                ContentUnavailableView("Thư mục trống", systemImage: "doc")
            } else {
                List(items) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                        Text(item.kind.title + (item.subtitle.map { " · \($0)" } ?? ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
