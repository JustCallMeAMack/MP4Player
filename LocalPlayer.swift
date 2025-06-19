import SwiftUI
import AVKit


struct LocalVideoPlayerApp: App {
    var body: some Scene {
        // Create 8 windows, each running its own player
        WindowGroup("Player 1") {
            VideoPlayerView()
        }
        WindowGroup("Player 2") {
            VideoPlayerView()
        }
        WindowGroup("Player 3") {
            VideoPlayerView()
        }
        WindowGroup("Player 4") {
            VideoPlayerView()
        }
        WindowGroup("Player 5") {
            VideoPlayerView()
        }
        WindowGroup("Player 6") {
            VideoPlayerView()
        }
        WindowGroup("Player 7") {
            VideoPlayerView()
        }
        WindowGroup("Player 8") {
            VideoPlayerView()
        }
    }
}
