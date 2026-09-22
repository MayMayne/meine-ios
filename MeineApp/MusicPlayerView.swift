import SwiftUI
import AVFoundation

struct MusicPlayerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let item: CatalogItem
    let root: URL

    @State private var player = AVPlayer()
    @State private var lines: [LyricLine] = []
    @State private var time: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playing = false
    @State private var stage = "half"
    @State private var timer: Timer?
    @State private var selectedLine: LyricLineShare?
    @State private var showEQ = false
    @State private var solidBackground = false

    private let bands = ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                if stage != "fullScreen" { topBar }
                if stage == "half" { artworkBlock }
                lyrics
                if stage != "fullScreen" { controls }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: start)
        .onDisappear {
            timer?.invalidate()
            player.pause()
        }
        .sheet(isPresented: $showEQ) { eqSheet }
        .sheet(item: $selectedLine) { pick in
            ShareLyricCard(title: item.title, artist: item.artists.joined(separator: ", "), line: pick.line.text)
        }
    }

    private var background: some View {
        ZStack {
            if solidBackground {
                Color(white: model.settings.intensity).ignoresSafeArea()
            } else if let image = cover {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 28)
                    .overlay(Color.black.opacity(0.45))
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "xmark") }
            Spacer()
            Button { showEQ = true } label: { Image(systemName: "slider.horizontal.3") }
            Button { solidBackground.toggle() } label: { Image(systemName: "paintpalette") }
            Button { cycleStage() } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
        }
        .font(.title3)
        .padding()
    }

    private var artworkBlock: some View {
        VStack(spacing: 8) {
            if let image = cover {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 260, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            Text(item.title).font(.title2.bold())
            Text(item.artists.joined(separator: ", ")).foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var lyrics: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    if lines.isEmpty {
                        Text("Nguồn chưa có lyric, hoặc file chưa sync.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(lines) { line in
                        Text(line.text)
                            .font(stage == "half" ? .title3 : .largeTitle)
                            .fontWeight(isActive(line) ? .bold : .regular)
                            .foregroundStyle(isActive(line) ? Color.white : Color.white.opacity(0.38))
                            .frame(maxWidth: .infinity)
                            .id(line.id)
                            .onTapGesture { selectedLine = LyricLineShare(line: line) }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
            .onTapGesture { if stage == "fullScreen" { stage = "full" } }
            .onChange(of: activeID) { _, id in
                guard let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Slider(value: Binding(get: { time }, set: { seek($0) }), in: 0...max(duration, 1))
                .tint(.white)
            HStack {
                Text(clock(time)).font(.caption.monospacedDigit())
                Spacer()
                Text(clock(duration)).font(.caption.monospacedDigit())
            }
            HStack(spacing: 28) {
                Image(systemName: "shuffle")
                Button { seek(max(0, time - 15)) } label: { Image(systemName: "backward.fill") }
                Button { toggle() } label: {
                    Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 58))
                }
                Button { seek(time + 15) } label: { Image(systemName: "forward.fill") }
                Button { cycleStage() } label: { Image(systemName: "quote.bubble") }
            }
            .font(.title2)
            HStack {
                Image(systemName: "airplayaudio")
                Spacer()
                Image(systemName: "list.bullet")
            }
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 22)
    }

    private var eqSheet: some View {
        NavigationStack {
            List {
                ForEach(bands.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(bands[index] + " Hz")
                        Slider(value: gain(index), in: -12...12)
                    }
                }
                Button("Phẳng") {
                    model.settings.eqGains = Array(repeating: 0, count: 10)
                    model.saveSettings()
                }
            }
            .navigationTitle("EQ")
            .toolbar { Button("Xong") { showEQ = false } }
        }
    }

    private var cover: UIImage? {
        guard let href = item.artwork, let url = MediaURL.resolve(href, root: root) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private var activeID: Int? { LyricCueParser.activeIndex(lines: lines, at: time) }

    private func isActive(_ line: LyricLine) -> Bool { line.id == activeID }

    private func cycleStage() {
        switch stage {
        case "half": stage = "full"
        case "full": stage = "fullScreen"
        default: stage = "half"
        }
    }

    private func start() {
        stage = model.settings.lyricStage
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        if let track = item.lyrics.first(where: \.isDefault) ?? item.lyrics.first,
           let url = MediaURL.resolve(track.href, root: root),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            lines = LyricCueParser.parse(text: text, format: track.format)
        }
        guard let media = item.playableMedia, let url = MediaURL.resolve(media.href, root: root) else { return }
        let playURL = url
        player.replaceCurrentItem(with: AVPlayerItem(url: playURL))
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task { @MainActor in
                time = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
                duration = player.currentItem?.duration.seconds.isFinite == true
                    ? player.currentItem!.duration.seconds : (item.duration ?? 0)
            }
        }
        toggle()
    }

    private func toggle() {
        if playing { player.pause() } else { player.play() }
        playing.toggle()
    }

    private func seek(_ value: TimeInterval) {
        player.seek(to: CMTime(seconds: value, preferredTimescale: 600))
        time = value
    }

    private func gain(_ index: Int) -> Binding<Double> {
        Binding(
            get: { model.settings.eqGains.indices.contains(index) ? model.settings.eqGains[index] : 0 },
            set: {
                if model.settings.eqGains.count < 10 {
                    model.settings.eqGains = Array(repeating: 0, count: 10)
                }
                model.settings.eqGains[index] = $0
                model.saveSettings()
            }
        )
    }

    private func clock(_ value: TimeInterval) -> String {
        guard value.isFinite else { return "0:00" }
        let total = Int(value)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct ShareLyricCard: View {
    let title: String
    let artist: String
    let line: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            card.padding()
            ShareLink(item: cardURL) {
                Label("Chia sẻ ảnh", systemImage: "square.and.arrow.up")
            }
            Button("Đóng") { dismiss() }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(line).font(.title2.bold())
            Text(title).font(.headline)
            Text(artist).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.12, green: 0.16, blue: 0.18))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var cardURL: URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("meine-lyric.png")
        if let data = render().pngData() {
            try? data.write(to: url)
        }
        return url
    }

    private func render() -> UIImage {
        let renderer = ImageRenderer(content: card.frame(width: 360))
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}
