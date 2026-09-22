import SwiftUI
import AVFoundation
import AVKit
import UIKit

struct VideoPlayerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let item: CatalogItem
    let root: URL

    @State private var player = AVPlayer()
    @State private var cues: [LyricLine] = []
    @State private var time: TimeInterval = 0
    @State private var duration: TimeInterval = 1
    @State private var showChrome = true
    @State private var playing = false
    @State private var subScale: Double = 1
    @State private var subOpacity: Double = 1
    @State private var timer: Timer?
    @State private var volumeHint = ""
    @State private var selectedCue: LyricLine?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            video
            if let cue = activeCue {
                Text(cue.text)
                    .font(.system(size: 18 * subScale, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(subOpacity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45 * subOpacity), in: RoundedRectangle(cornerRadius: 6))
                    .padding(.bottom, showChrome ? 150 : 36)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            if showChrome { chrome }
            if !volumeHint.isEmpty {
                Text(volumeHint)
                    .padding(10)
                    .background(.black.opacity(0.6), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .statusBarHidden(!showChrome)
        .persistentSystemOverlays(showChrome ? .automatic : .hidden)
        .onAppear(perform: start)
        .onDisappear {
            timer?.invalidate()
            player.pause()
        }
        .gesture(volumeGesture)
        .sheet(item: $selectedCue) { cue in
            ShareLyricCard(title: item.title, artist: "Khung hình", line: cue.text)
        }
    }

    private var video: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .onTapGesture { showChrome.toggle() }
    }

    private var chrome: some View {
        VStack {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                Spacer()
                Button { selectedCue = activeCue } label: { Image(systemName: "square.and.arrow.up") }
                    .disabled(activeCue == nil)
            }
            .font(.title3)
            .padding()
            Spacer()
            VStack(spacing: 14) {
                HStack {
                    Text(clock(time)).font(.caption.monospacedDigit())
                    Slider(value: Binding(get: { time }, set: seek), in: 0...max(duration, 1))
                    Text(clock(max(0, duration - time))).font(.caption.monospacedDigit())
                }
                HStack(spacing: 36) {
                    Button { seek(max(0, time - 10)) } label: { Image(systemName: "gobackward.10") }
                    Button { toggle() } label: {
                        Image(systemName: playing ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 52))
                    }
                    Button { seek(time + 10) } label: { Image(systemName: "goforward.10") }
                }
                HStack {
                    Image(systemName: "lock")
                    Image(systemName: "pip")
                    Text("1x").font(.caption.bold())
                    Image(systemName: "text.bubble")
                    Spacer()
                    Button { showChrome = false } label: { Image(systemName: "chevron.down") }
                }
                HStack {
                    Text("Cỡ sub")
                    Slider(value: $subScale, in: 0.7...1.8)
                    Text("Đậm")
                    Slider(value: $subOpacity, in: 0.3...1)
                }
                .font(.caption)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .top, endPoint: .bottom))
        }
        .foregroundStyle(.white)
    }

    private var volumeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !showChrome else { return }
                let delta = -value.translation.height / 300
                if value.startLocation.x < 140 {
                    let next = min(1, max(0, Double(AVAudioSession.sharedInstance().outputVolume) + delta))
                    volumeHint = "Âm lượng \(Int(next * 100))%"
                } else if value.startLocation.x > UIScreen.main.bounds.width - 140 {
                    UIScreen.main.brightness = min(1, max(0, UIScreen.main.brightness + delta))
                    volumeHint = "Sáng \(Int(UIScreen.main.brightness * 100))%"
                }
            }
            .onEnded { _ in volumeHint = "" }
    }

    private var activeCue: LyricLine? {
        guard let index = LyricCueParser.activeIndex(lines: cues, at: time) else { return nil }
        return cues[index]
    }

    private func start() {
        if let track = item.subtitles.first(where: \.isDefault) ?? item.subtitles.first,
           track.kind != "hard",
           let url = MediaURL.resolve(track.href, root: root),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            cues = LyricCueParser.parseSRT(text)
        }
        guard let media = item.playableMedia, let url = MediaURL.resolve(media.href, root: root) else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor in
                time = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
                if player.currentItem?.duration.seconds.isFinite == true {
                    duration = player.currentItem!.duration.seconds
                }
            }
        }
        toggle()
    }

    private func toggle() {
        playing ? player.pause() : player.play()
        playing.toggle()
    }

    private func seek(_ value: TimeInterval) {
        let target = min(max(0, value), duration)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        time = target
    }

    private func clock(_ value: TimeInterval) -> String {
        let total = Int(value.isFinite ? value : 0)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct ClipFeedView: View {
    @Environment(\.dismiss) private var dismiss
    let loaded: LoadedSource
    let feed: String
    var startRef: String?

    var body: some View {
        let clips = loaded.items.values
            .filter { $0.kind == .clip && ($0.feed == feed || feed == "for-you") }
            .sorted { $0.ref < $1.ref }
        ZStack(alignment: .topLeading) {
            TabView {
                ForEach(clips.isEmpty ? [] : clips) { clip in
                    ClipPage(item: clip, root: loaded.root)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color.black)
            Button { dismiss() } label: {
                Image(systemName: "xmark").padding(12).background(.black.opacity(0.4), in: Circle())
            }
            .padding()
            .foregroundStyle(.white)
        }
        .ignoresSafeArea()
    }
}

struct ClipPage: View {
    let item: CatalogItem
    let root: URL
    @State private var player = AVPlayer()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VideoPlayer(player: player).ignoresSafeArea()
            VStack(alignment: .leading) {
                Text(item.title).font(.headline)
                Text(item.creator ?? "").font(.subheadline)
            }
            .foregroundStyle(.white)
            .padding(20)
            .shadow(radius: 4)
        }
        .onAppear {
            guard let media = item.playableMedia, let url = MediaURL.resolve(media.href, root: root) else { return }
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
        }
        .onDisappear { player.pause() }
    }
}
