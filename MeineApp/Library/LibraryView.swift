import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @State private var picking = false

    var body: some View {
        NavigationStack {
            Group {
                if library.sources.isEmpty {
                    ContentUnavailableView(
                        "Chưa có nguồn",
                        systemImage: "folder.badge.plus",
                        description: Text("Chọn một thư mục trên máy. Meine tự nhận phim, nhạc, tranh và chữ theo cấu trúc thư mục.")
                    )
                } else {
                    List {
                        ForEach(library.sources) { source in
                            NavigationLink {
                                SourceDetailView(source: source)
                            } label: {
                                SourceRow(source: source)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { library.sources[$0] }.forEach(library.remove)
                        }
                    }
                }
            }
            .navigationTitle("Thư viện")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Thêm", systemImage: "plus") { picking = true }
                }
            }
            .fileImporter(
                isPresented: $picking,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    library.add(url: url)
                }
            }
            .alert("Không lưu được nguồn", isPresented: errorVisible) {
                Button("Đóng", role: .cancel) { library.lastError = nil }
            } message: {
                Text(library.lastError ?? "")
            }
        }
    }

    private var errorVisible: Binding<Bool> {
        Binding(
            get: { library.lastError != nil },
            set: { if !$0 { library.lastError = nil } }
        )
    }
}

private struct SourceRow: View {
    let source: SourceRecord

    var body: some View {
        HStack {
            Image(systemName: source.isLocked ? "lock.fill" : "folder")
                .foregroundStyle(Palette.accent)
            VStack(alignment: .leading) {
                Text(source.isLocked ? "Nguồn đã khoá" : source.title)
                if source.isLocked {
                    Text("Mở khoá để xem tên và nội dung")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
