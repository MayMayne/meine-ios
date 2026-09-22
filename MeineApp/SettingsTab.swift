import SwiftUI

struct SettingsTab: View {
    @EnvironmentObject private var model: AppModel
    @State private var lockID = ""
    @State private var lockPassword = ""

    private let themes: [(String, String, String)] = [
        ("Biển pastel", "#E7F6F4", "#5BB8B0"),
        ("Đen", "#111111", "#8FD0C8"),
        ("Xám", "#3A3A3A", "#D0D0D0"),
        ("Vàng", "#F3E2B3", "#8A6A2F"),
        ("Be", "#F4E7D4", "#8C6239"),
        ("Trắng", "#FFFFFF", "#3D8F88"),
        ("Xanh lá", "#DDE8D5", "#3E6B45")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nền app") {
                    ForEach(themes, id: \.0) { name, bg, accent in
                        Button(name) {
                            model.settings.backgroundHex = bg
                            model.settings.accentHex = accent
                            model.settings.cardHex = name == "Đen" ? "#1C1C1C" : "#FFFFFF"
                            model.saveSettings()
                        }
                    }
                    Button("Khôi phục xanh biển") {
                        model.settings = .builtIn
                        model.saveSettings()
                    }
                }
                Section("Khoá nguồn trên máy") {
                    TextField("id nguồn", text: $lockID)
                    SecureField("Mật khẩu", text: $lockPassword)
                    Button("Đặt mật khẩu") {
                        SourceLock.setPassword(lockPassword, sourceID: lockID)
                        lockPassword = ""
                    }
                    .disabled(lockID.isEmpty || lockPassword.isEmpty)
                }
                Section("Nguồn đã thêm") {
                    ForEach(model.sources) { source in
                        VStack(alignment: .leading) {
                            Text(source.name)
                            Text(source.id).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(model.palette.background)
            .navigationTitle("Cài đặt")
        }
    }
}
