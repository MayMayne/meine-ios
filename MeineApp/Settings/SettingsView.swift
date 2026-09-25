import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Giao diện") {
                    LabeledContent("Màu chính", value: "#8ECAE6")
                    LabeledContent("Điểm nhấn", value: "#219EBC")
                    Text("Nền đọc, EQ, player và dịch sẽ vào các bản sau. Bản này mở thư mục và nhận nội dung.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Nguồn") {
                    LabeledContent("Rule JSON/YAML", value: "Chưa")
                    LabeledContent("JavaScriptCore", value: "Chưa")
                    LabeledContent("Thư mục local", value: "Có")
                }
                Section {
                    Text("Meine 0.1.0 · iOS 18 · không ký")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Cài đặt")
        }
    }
}
