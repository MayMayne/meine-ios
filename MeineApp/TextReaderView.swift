import SwiftUI

struct TextReaderView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let item: CatalogItem
    let root: URL

    @State private var chapterIndex = 0
    @State private var bodyText = ""
    @State private var auto = false
    @State private var showTools = false
    @State private var page = 0
    @State private var noteSource = ""
    @State private var noteWrong = ""
    @State private var noteFixed = ""

    private let paper: [(String, String)] = [
        ("Đen", "#111111"), ("Xám", "#4A4A4A"), ("Vàng", "#F3E2B3"),
        ("Be", "#F4E7D4"), ("Trắng", "#FFFFFF"), ("Xanh lá", "#DDE8D5")
    ]

    var body: some View {
        ZStack {
            paperColor.ignoresSafeArea()
            VStack(spacing: 0) {
                bar
                if model.settings.readerMode == "page" {
                    pageView
                } else {
                    scrollView
                }
            }
        }
        .foregroundStyle(ink)
        .onAppear(perform: load)
        .sheet(isPresented: $showTools) { tools }
    }

    private var bar: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "xmark") }
            Spacer()
            Text(item.chapters.indices.contains(chapterIndex) ? item.chapters[chapterIndex].title : item.title)
                .lineLimit(1)
            Spacer()
            Button { showTools = true } label: { Image(systemName: "textformat.size") }
        }
        .padding()
    }

    private var scrollView: some View {
        ScrollView {
            Text(bodyText)
                .font(.system(size: 18 * model.settings.fontScale))
                .lineSpacing(8)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pageView: some View {
        let chunks = pages
        return VStack {
            Text(chunks.indices.contains(page) ? chunks[page] : bodyText)
                .font(.system(size: 18 * model.settings.fontScale))
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            HStack {
                Button("Trước") { page = max(0, page - 1) }
                Spacer()
                Text("\(min(page + 1, max(chunks.count, 1)))/\(max(chunks.count, 1))")
                Spacer()
                Button("Sau") { page = min(max(chunks.count - 1, 0), page + 1) }
            }
            .padding()
        }
    }

    private var tools: some View {
        NavigationStack {
            Form {
                Section("Nền") {
                    ForEach(paper, id: \.1) { name, hex in
                        Button(name) { model.settings.backgroundHex = hex; model.saveSettings() }
                    }
                    Slider(value: $model.settings.intensity, in: 0.15...1) { Text("Đậm nhạt nền") }
                }
                Section("Chữ") {
                    Slider(value: $model.settings.textIntensity, in: 0.4...1) { Text("Đậm chữ") }
                    Slider(value: $model.settings.fontScale, in: 0.8...1.6) { Text("Cỡ") }
                    Picker("Đọc", selection: $model.settings.readerMode) {
                        Text("Cuộn").tag("scroll")
                        Text("Lật trang").tag("page")
                    }
                    Toggle("Cuộn tự động", isOn: $auto)
                    Slider(value: $model.settings.autoScrollSpeed, in: 0.1...1) { Text("Tốc độ") }
                }
                Section("Xưng hô") {
                    ForEach(model.addressBook) { row in
                        Text("\(row.source) → \(row.preferred) (\(row.pronoun))")
                    }
                    if model.addressBook.isEmpty {
                        Text("Chưa có dòng. Hint của nguồn sẽ hiện khi catalog có translationHints.")
                    }
                }
                Section("Prompt dịch") {
                    TextField("Prompt", text: $model.settings.translationPrompt, axis: .vertical)
                }
                Section("Note lỗi dịch / TTS") {
                    TextField("Từ gốc", text: $noteSource)
                    TextField("Bản sai", text: $noteWrong)
                    TextField("Cách đúng", text: $noteFixed)
                    Button("Ghi note") {
                        let note = ReaderNote(id: UUID(), kind: "translate", source: noteSource, wrong: noteWrong, corrected: noteFixed)
                        model.notes.insert(note, at: 0)
                        model.saveNotes()
                        noteSource = ""; noteWrong = ""; noteFixed = ""
                    }
                    ForEach(model.notes) { note in
                        Text("\(note.source): \(note.wrong) → \(note.corrected)").font(.caption)
                    }
                }
                Section("Dịch") {
                    if let text = shareText {
                        ShareLink(item: prompt(text)) { Label("Đưa sang app dịch", systemImage: "character.book.closed") }
                    }
                    Text("Dịch AI dùng prompt, bảng xưng hô và note ở trên. App không gọi API nếu bạn chưa gắn nhà cung cấp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Đọc")
            .toolbar { Button("Xong") { showTools = false; model.saveSettings() } }
        }
    }

    private var paperColor: Color {
        let base = Color(hex: model.settings.backgroundHex) ?? Color(hex: "#F4E7D4")!
        return base.opacity(0.55 + model.settings.intensity * 0.45)
    }

    private var ink: Color {
        Color(hex: model.settings.inkHex)?.opacity(0.4 + model.settings.textIntensity * 0.6) ?? .primary
    }

    private var pages: [String] {
        stride(from: 0, to: bodyText.count, by: 700).map { offset in
            let start = bodyText.index(bodyText.startIndex, offsetBy: offset)
            let end = bodyText.index(start, offsetBy: 700, limitedBy: bodyText.endIndex) ?? bodyText.endIndex
            return String(bodyText[start..<end])
        }
    }

    private var shareText: String? { bodyText.isEmpty ? nil : String(bodyText.prefix(1500)) }

    private func prompt(_ text: String) -> String {
        let address = model.addressBook.map { "\($0.source) = \($0.preferred), gọi là \($0.pronoun)" }.joined(separator: "\n")
        let notes = model.notes.prefix(12).map { "\($0.source) đừng dịch thành \($0.wrong), hãy \($0.corrected)" }.joined(separator: "\n")
        return """
        \(model.settings.translationPrompt)
        Thể loại: \(item.genreHint ?? item.genres.first ?? "chung")
        Xưng hô:
        \(address)
        Lỗi cần tránh:
        \(notes)
        Văn bản:
        \(text)
        """
    }

    private func load() {
        for hint in item.addressHints where !model.addressBook.contains(where: { $0.source == hint.source }) {
            model.addressBook.append(AddressRow(id: UUID(), source: hint.source, preferred: hint.preferred, pronoun: hint.pronoun))
        }
        model.saveAddress()
        guard item.chapters.indices.contains(chapterIndex),
              let href = item.chapters[chapterIndex].href,
              let url = MediaURL.resolve(href, root: root),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            bodyText = "Chưa đọc được chương. Kiểm tra href trong catalog."
            return
        }
        bodyText = text
    }
}
