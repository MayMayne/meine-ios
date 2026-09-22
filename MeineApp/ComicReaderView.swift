import SwiftUI
import UIKit

struct ComicReaderView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let item: CatalogItem
    let root: URL

    @State private var page = 0
    @State private var auto = false
    @State private var holding = false

    private var pages: [PageRef] { item.chapters.flatMap(\.pages) }

    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                    Spacer()
                    Text(item.title).lineLimit(1)
                    Spacer()
                    Menu("Đọc") {
                        Button("Webtoon") { model.settings.comicMode = "webtoon" }
                        Button("Trang trái sang phải") { model.settings.comicMode = "ltr" }
                        Button("Trang phải sang trái") { model.settings.comicMode = "rtl" }
                        Button("Trang dọc") { model.settings.comicMode = "vertical" }
                        Button(auto ? "Tắt tự cuộn" : "Bật tự cuộn") { auto.toggle() }
                    }
                }
                .padding()
                content
            }
        }
        .gesture(hold)
        .onAppear {
            if let mode = item.defaultReading { model.settings.comicMode = mode }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.settings.comicMode == "webtoon" || model.settings.comicMode == "vertical" {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                        comicImage(page)
                            .padding(.horizontal, model.settings.comicMargin * 40)
                    }
                }
            }
        } else {
            TabView(selection: $page) {
                ForEach(Array(displayPages.enumerated()), id: \.offset) { index, pageRef in
                    comicImage(pageRef)
                        .tag(index)
                        .padding(.horizontal, model.settings.comicMargin * 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, model.settings.comicMode == "rtl" ? .rightToLeft : .leftToRight)
        }
    }

    private var displayPages: [PageRef] {
        model.settings.comicMode == "rtl" ? Array(pages.reversed()) : pages
    }

    private func comicImage(_ page: PageRef) -> some View {
        Group {
            if let url = MediaURL.resolve(page.href, root: root),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ContentUnavailableView("Thiếu ảnh", systemImage: "photo", description: Text(page.href))
            }
        }
    }

    private var paper: Color {
        (Color(hex: model.settings.backgroundHex) ?? .black).opacity(0.4 + model.settings.intensity * 0.6)
    }

    private var hold: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .onEnded { _ in holding = true }
            .simultaneously(with: DragGesture().onEnded { value in
                guard holding else { return }
                if value.translation.height < -20 { page = min(pages.count - 1, page + 1) }
                if value.translation.height > 20 { page = max(0, page - 1) }
                holding = false
            })
    }
}
