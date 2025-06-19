import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @State private var player: AVPlayer? = nil
    @State private var selectedFile: URL? = nil
    @State private var playbackRate: Float = 1.0
    @State private var showControls = true
    @State private var lastInteractionTime = Date()
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var playlist: [URL] = []
    @State private var currentIndex = 0
    @State private var showPlaylist = false
    @State private var isLooping = false
    @State private var volume: Float = 1.0
    @State private var showVolumeSlider = false
    @State private var showSpeedSlider = false


    private let fadeDelay: TimeInterval = 3

    var body: some View {
        HStack(spacing: 0) {
            VStack{
                
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let player = player {
                        PlayerView(player: player) { window in
                            guard let window = window else { return }

                                // Remove title bar and traffic light buttons
                                window.titleVisibility = .hidden
                                window.titlebarAppearsTransparent = true
                                window.styleMask.remove(.titled)
                                window.styleMask.remove(.closable)
                                window.styleMask.remove(.miniaturizable)
                                window.styleMask.remove(.resizable)
                                window.isMovableByWindowBackground = true
                            }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                player.play()
                                player.rate = playbackRate
                            }
                    } else {
                        Text("No video selected")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }

                    if showControls {
                        VStack {
                            Spacer()

                            controlPanel
                                .padding()
                                .transition(.opacity)
                                .background(Color.black.opacity(0.3).blur(radius: 10))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            } .frame(maxWidth: .infinity)
            
            // 📃 Playlist side panel
            if showPlaylist {
                VStack(alignment: .leading) {
                    Text("Playlist")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(Array(playlist.enumerated()), id: \.offset) { index, url in
                            Button(action: {
                                playVideo(at: index)
                            }) {
                                HStack {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .foregroundColor(index == currentIndex ? .blue : .primary)
                                    Spacer()
                                    if index == currentIndex {
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(width: 250)
                    Spacer()
                    Button(action: shufflePlaylist) {
                        Image(systemName: "shuffle")
                            .foregroundColor(.white)
                        }
                            .disabled(playlist.count <= 1)
                    Button(action: {
                        isLooping.toggle()
                    }) {
                        Label("", systemImage: isLooping ? "repeat.1" : "repeat")
                    }
                    .tint(isLooping ? .green : .white)
                    }
                }
        }
        .onAppear {
            startInactivityTimer()
            addPlaybackObserver()
        }
        .onTapGesture {
            showControls = true
            lastInteractionTime = Date()
        }
        .onHover { hovering in
            if hovering {
                showControls = true
                lastInteractionTime = Date()
            }
        }
        .onChange(of: volume) { _, newVolume in
            player?.volume = newVolume
        }

        .animation(.easeInOut(duration: 0.25), value: showControls)
        .frame(minWidth: 720, minHeight: 420)
    }

    var controlPanel: some View {
        
        HStack(spacing: 20) {
            Button("Add Video") {
                selectVideo()
                }
            Button(action: {
                showPlaylist.toggle()
            }) {
                Label(showPlaylist ? "Hide Playlist" : "Show Playlist", systemImage: "list.bullet")
            }

            
            
            Button(action: { player?.pause() }) {
                Image(systemName: "pause.fill")
            }

            Button(action: {
                guard let player = player else { return }
                guard playlist.indices.contains(currentIndex) else { return }
                let url = playlist[currentIndex]
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
                player.play()
            }) {
                Image(systemName: "play.fill")
            }
         
            Button("Previous") {
                let prevIndex = currentIndex - 1
                if playlist.indices.contains(prevIndex) {
                    playVideo(at: prevIndex)
                }
            }
            .disabled(playlist.isEmpty || currentIndex <= 0)

            Button("Next") {
                playNext()
                }
                .disabled(playlist.isEmpty || currentIndex >= playlist.count - 1)
            
            Button(action: {
                guard let player = player else { return }
                let currentTime = player.currentTime()
                let newTime = CMTimeGetSeconds(currentTime) - 10
                player.seek(to: CMTime(seconds: max(newTime, 0), preferredTimescale: 600))
            }) {
                Image(systemName: "gobackward.10")
            }

            Button(action: {
                guard let player = player else { return }
                let currentTime = player.currentTime()
                let newTime = CMTimeGetSeconds(currentTime) + 10
                player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
            }) {
                Image(systemName: "goforward.10")
            }
            
            VStack{
                HStack {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .onTapGesture {
                            withAnimation {
                                showVolumeSlider.toggle()
                        }
                    }
                        if showVolumeSlider {
                            Slider(value: $volume, in: 0...1)
                                .frame(width: 100)
                            }

                        }

                    HStack {
                        Image(systemName: "forward.circle.fill")
                            .onTapGesture {
                                withAnimation {
                            showSpeedSlider.toggle()
                        }
                    }
                        if showSpeedSlider {
                            Slider(value: $playbackRate, in: 0.5...2.0, step: 0.1)
                                .frame(width: 100)
                                Text(String(format: "%.1fx", playbackRate))
                        }
                    }
                        .onChange(of: playbackRate) { _, newRate in
                            player?.rate = newRate
            }
            }

            Spacer()
            
            
        }
        .foregroundColor(.white)
    }

    
    
    func selectVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            let urls = panel.urls
            if !urls.isEmpty {
                // Append to playlist
                playlist.append(contentsOf: urls)

                // If no current video, start playback
                if player == nil || player?.currentItem == nil {
                    currentIndex = 0
                    let firstURL = playlist[currentIndex]
                    player = AVPlayer(url: firstURL)
                    player?.rate = playbackRate
                    addPlaybackObserver()
                    player?.play()
                }
            }
        }
    }



    func startInactivityTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if Date().timeIntervalSince(lastInteractionTime) > fadeDelay {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    func playVideo(at index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        let url = playlist[index]
        if player == nil {
            player = AVPlayer(url: url)
        } else {
            player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        }
        player?.play()
    }


        func playNext() {
            let nextIndex = currentIndex + 1
            if playlist.indices.contains(nextIndex) {
                playVideo(at: nextIndex)
            }
        }

    func addPlaybackObserver() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
            if isLooping {
                player?.seek(to: .zero)
                player?.play()
            } else {
                playNext()
                }
            }
        }
    
    func shufflePlaylist() {
        guard playlist.count > 1 else { return }
        let currentURL = playlist[currentIndex]

        playlist.shuffle()

        if let newIndex = playlist.firstIndex(of: currentURL) {
            currentIndex = newIndex
        } else {
            // Fallback: if the video is somehow not found (rare case)
            currentIndex = 0
            playVideo(at: 0)
        }
    }


}
