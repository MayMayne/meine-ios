import SwiftUI
import UniformTypeIdentifiers

struct FolderImportView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var message = "Chọn thư mục gốc nguồn, nơi có manifest.json."
    @State private var picking = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(message)
                    .foregroundStyle(.secondary)
                Button("Chọn thư mục") { picking = true }
                    .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(20)
            .background(model.palette.background)
            .navigationTitle("Thêm nguồn")
            .toolbar {
                Button("Đóng") { dismiss() }
            }
            .fileImporter(
                isPresented: $picking,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { importFolder(url) }
                case .failure(let error):
                    message = error.localizedDescription
                }
            }
        }
    }

    private func importFolder(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let report = SourceChecker.check(root: url)
        guard let manifest = report.manifest, report.canOpen else {
            message = report.issues.first?.message ?? "Không mở được nguồn."
            return
        }
        model.remember(url: url, manifest: manifest)
        message = "Đã thêm \(manifest.name)."
        dismiss()
    }
}
