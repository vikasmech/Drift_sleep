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

    func localURL(_ sound: Soundscape) -> URL {
        directory.appendingPathComponent(sound.filename)
    }

    func bundledURL(_ sound: Soundscape) -> URL? {
        let file = sound.filename as NSString
        return Bundle.main.url(forResource: file.deletingPathExtension, withExtension: file.pathExtension)
    }

    func isSaved(_ sound: Soundscape) -> Bool {
        sound.isFree && (FileManager.default.fileExists(atPath: localURL(sound).path) || bundledURL(sound) != nil)
    }

    static func serverURL(_ value: String) -> URL? {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
        return url
    }

    func ensure(_ sound: Soundscape, server: String) async throws -> URL {
        guard sound.isFree else { throw LibraryError.previewOnly }
        let saved = localURL(sound)
        if FileManager.default.fileExists(atPath: saved.path) {
            do { try validate(saved, freeLoop: true); return saved }
            catch { /* Keep a corrupt cache entry until its replacement is valid. */ }
        }
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
            let destination = localURL(sound)
            let temporary = directory.appendingPathComponent(UUID().uuidString + ".part")
            defer { try? FileManager.default.removeItem(at: temporary) }
            if let bundled = bundledURL(sound) {
                try FileManager.default.copyItem(at: bundled, to: temporary)
            } else {
                guard let base = Self.serverURL(server) else { throw LibraryError.invalidServer }
                let url = base.appendingPathComponent("api/audio").appendingPathComponent(sound.filename)
                let (download, response) = try await session.download(from: url)
                defer { try? FileManager.default.removeItem(at: download) }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw LibraryError.unavailable
                }
                let mime = http.mimeType?.lowercased() ?? ""
                guard mime.hasPrefix("audio/") || mime == "application/octet-stream" else {
                    throw LibraryError.invalidAudio
                }
                try FileManager.default.moveItem(at: download, to: temporary)
            }
            try validate(temporary, freeLoop: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                _ = try FileManager.default.replaceItemAt(destination, withItemAt: temporary)
            } else {
                try FileManager.default.moveItem(at: temporary, to: destination)
            }
            return destination
        }
        pending[sound.id] = task
        defer { pending[sound.id] = nil }
        return try await task.value
    }

    func preview(_ sound: Soundscape, server: String) async throws -> URL {
        guard !sound.isFree, let base = Self.serverURL(server) else { throw LibraryError.invalidServer }
        let url = base.appendingPathComponent("api/audio").appendingPathComponent(sound.filename)
        let (temporary, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              (http.mimeType ?? "").hasPrefix("audio/") else {
            try? FileManager.default.removeItem(at: temporary)
            throw LibraryError.unavailable
        }
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
            let file = try AVAudioFile(forReading: url)
            guard file.fileFormat.settings[AVFormatIDKey] as? UInt32 == kAudioFormatLinearPCM,
                  audio.duration >= 20, audio.duration <= 60 else { throw LibraryError.invalidAudio }
        } else {
            // Reject full premium masters: a timer alone is not an access boundary.
            guard audio.duration <= 31 else { throw LibraryError.invalidAudio }
        }
    }

    func remove(_ sound: Soundscape) throws {
        guard sound.isFree else { return }
        guard pending[sound.id] == nil else { return }
        if FileManager.default.fileExists(atPath: localURL(sound).path) {
            try FileManager.default.removeItem(at: localURL(sound))
        }
    }
}
