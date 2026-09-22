import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            HomeTab()
                .tabItem { Label("Nhà", systemImage: "square.grid.2x2") }
            LibraryTab()
                .tabItem { Label("Thư viện", systemImage: "books.vertical") }
            SettingsTab()
                .tabItem { Label("Cài đặt", systemImage: "slider.horizontal.3") }
        }
        .background(model.palette.background.ignoresSafeArea())
    }
}

struct HomeTab: View {
    @EnvironmentObject private var model: AppModel
    @State private var picking = false

    var body: some View {
        NavigationStack {
            Group {
                if model.sources.isEmpty {
                    empty
                } else {
                    List(model.sources) { source in
                        NavigationLink {
                            SourceHomeView(source: source)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name).font(.headline)
                                Text(source.id).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(model.palette.background)
            .navigationTitle("Meine")
            .toolbar {
                Button("Thêm nguồn", systemImage: "plus") { picking = true }
            }
            .sheet(isPresented: $picking) {
                FolderImportView()
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Text("Chưa có nguồn")
                .font(.title2)
            Text("Chọn một thư mục có manifest.json. Local, sau này HTTP và Drive cũng đi vào đây.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Thêm thư mục") { picking = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
    }
}

struct LibraryTab: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Đã lưu") {
                    if model.library.isEmpty {
                        Text("Chưa thêm tác phẩm nào.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.library) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.title)
                            Text(entry.kind).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Danh sách") {
                    ForEach(model.lists) { list in
                        HStack {
                            Text(list.title)
                            Spacer()
                            Text(list.isPublic ? "Public" : "Private")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(model.palette.background)
            .navigationTitle("Thư viện")
        }
    }
}
