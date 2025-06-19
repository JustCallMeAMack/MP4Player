import Foundation
import AVFoundation

class PlaybackMemoryManager {
    static let shared = PlaybackMemoryManager()
    private let memoryFileURL: URL
    
    private var memory: [String: Double] = [:]

    private init() {
        let fileName = "playback_memory.json"
        let docDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = docDir.appendingPathComponent("LocalVideoPlayer")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.memoryFileURL = dir.appendingPathComponent(fileName)
        load()
    }

    func savePlayback(for url: URL?, time: CMTime) {
        guard let url = url else { return }
        memory[url.path] = CMTimeGetSeconds(time)
        save()
    }

    func loadPlayback(for url: URL) -> CMTime? {
        if let seconds = memory[url.path] {
            return CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
        }
        return nil
    }

    private func load() {
        guard let data = try? Data(contentsOf: memoryFileURL),
              let dict = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return
        }
        memory = dict
    }

    private func save() {
        if let data = try? JSONEncoder().encode(memory) {
            try? data.write(to: memoryFileURL)
        }
    }
}
