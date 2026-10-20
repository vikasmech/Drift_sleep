import AVFoundation
import Foundation

enum LibraryError: LocalizedError {
    case invalidServer, unavailable, invalidAudio, previewOnly
    var errorDescription: String? {
        switch self {
        case .invalidServer: return "Enter a valid HTTPS audio server address in Settings."
        case .unavailable: return "Audio is unavailable. Check your connection and audio server, then try again."
        case .invalidAudio: return "The server returned an invalid audio file. The previous download has been kept."
        case .previewOnly: return "Only the five free sounds can be saved for unlimited listening."
        }
    }
}

/// Files are validated before an atomic replacement. Free sounds never stream at loop boundaries.
@MainActor
final class AudioLibrary {
    private let directory: URL
    private var pending: [String: Task<URL, Error>] = [:]
    private let session: URLSession

    init() {
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DriftAudio", isDirectory: true)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        session = URLSession(configuration: config)
    }

    func localURL(_ sound: Soundscape, filename: String? = nil) -> URL {
        directory.appendingPathComponent(filename ?? sound.filename)
    }

    func bundledURL(_ sound: Soundscape) -> URL? {
        for name in sound.playableFilenames {
            if let url = locateInBundle(name) { return url }
        }
        return nil
    }

    func isSaved(_ sound: Soundscape) -> Bool {
        sound.isFree && (cachedURL(sound) != nil || bundledURL(sound) != nil)
    }

    static func serverURL(_ value: String) -> URL? {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        return url
    }

    func ensure(_ sound: Soundscape, server: String) async throws -> URL {
        guard sound.isFree else { throw LibraryError.previewOnly }
        if let cached = cachedURL(sound) { return cached }
        if let bundled = bundledURL(sound) {
            try validate(bundled, freeLoop: true)
            return bundled
        }
        if let task = pending[sound.id] { return try await task.value }
        let task = Task<URL, Error> {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var folder = directory
            try folder.setResourceValues(values)
            if let cached = cachedURL(sound) { return cached }
            if let bundled = bundledURL(sound) {
                try validate(bundled, freeLoop: true)
                return bundled
            }
            guard Self.serverURL(server) != nil else { throw LibraryError.invalidServer }
            var lastError: Error = LibraryError.unavailable
            for name in sound.playableFilenames {
                do { return try await downloadAndStore(sound: sound, server: server, filename: name) }
                catch { lastError = error }
            }
            throw lastError
        }
        pending[sound.id] = task
        defer { pending[sound.id] = nil }
        return try await task.value
    }

    func preview(_ sound: Soundscape, server: String) async throws -> URL {
        guard !sound.isFree, Self.serverURL(server) != nil else { throw LibraryError.invalidServer }
        let (temporary, _) = try await fetchAudio(server: server, filename: sound.filename)
        do {
            try validate(temporary, freeLoop: false)
            return temporary
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }

    func validate(_ url: URL, freeLoop: Bool) throws {
        let audio = try AVAudioPlayer(contentsOf: url)
        guard audio.duration.isFinite, audio.duration > 0 else { throw LibraryError.invalidAudio }
        if freeLoop {
            guard audio.duration >= 20, audio.duration <= 60 else { throw LibraryError.invalidAudio }
            if url.pathExtension.lowercased() == "wav" {
                let file = try AVAudioFile(forReading: url)
                let format = (file.fileFormat.settings[AVFormatIDKey] as? NSNumber)?.uint32Value
                guard format == kAudioFormatLinearPCM else { throw LibraryError.invalidAudio }
            }
        } else {
            // Reject full premium masters: a timer alone is not an access boundary.
            guard audio.duration <= 31 else { throw LibraryError.invalidAudio }
        }
    }

    func remove(_ sound: Soundscape) throws {
        guard sound.isFree else { return }
        guard pending[sound.id] == nil else { return }
        for name in sound.playableFilenames {
            let url = localURL(sound, filename: name)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }

    private func cachedURL(_ sound: Soundscape) -> URL? {
        for name in sound.playableFilenames {
            let url = localURL(sound, filename: name)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                try validate(url, freeLoop: true)
                return url
            } catch {
                continue
            }
        }
        return nil
    }

    private func locateInBundle(_ filename: String) -> URL? {
        let file = filename as NSString
        let name = file.deletingPathExtension
        let ext = file.pathExtension
        if let url = Bundle.main.url(forResource: name, withExtension: ext) { return url }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") {
            return url
        }
        guard let enumerator = FileManager.default.enumerator(
            at: Bundle.main.bundleURL,
            includingPropertiesForKeys: nil
        ) else { return nil }
        for case let url as URL in enumerator where url.lastPathComponent == filename {
            return url
        }
        return nil
    }

    private func downloadAndStore(sound: Soundscape, server: String, filename: String) async throws -> URL {
        let destination = localURL(sound, filename: filename)
        let temporary = directory.appendingPathComponent(UUID().uuidString + ".part")
        defer { try? FileManager.default.removeItem(at: temporary) }
        let (download, _) = try await fetchAudio(server: server, filename: filename)
        defer { try? FileManager.default.removeItem(at: download) }
        if FileManager.default.fileExists(atPath: temporary.path) {
            try FileManager.default.removeItem(at: temporary)
        }
        try FileManager.default.moveItem(at: download, to: temporary)
        try validate(temporary, freeLoop: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: destination)
        }
        return destination
    }

    private func fetchAudio(server: String, filename: String) async throws -> (URL, HTTPURLResponse) {
        guard let base = Self.serverURL(server) else { throw LibraryError.invalidServer }
        let url = base.appendingPathComponent("api/audio").appendingPathComponent(filename)
        let (download, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            try? FileManager.default.removeItem(at: download)
            throw LibraryError.unavailable
        }
        let mime = http.mimeType?.lowercased() ?? ""
        guard mime.hasPrefix("audio/") || mime == "application/octet-stream" else {
            try? FileManager.default.removeItem(at: download)
            throw LibraryError.invalidAudio
        }
        return (download, http)
    }
}
