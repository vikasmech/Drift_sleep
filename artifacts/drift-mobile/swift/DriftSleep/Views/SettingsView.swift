import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DriftStore
    @State private var draft = ""
    @State private var serverError: String?
    @State private var saved = false

    var body: some View {
        Screen(title: "Settings") {
            Card {
                Text("Usual sound").font(.headline).foregroundStyle(Theme.text)
                Picker("Usual sound", selection: Binding(get: { store.usualID }, set: { store.usualID = $0 })) {
                    ForEach(Soundscape.free) { Text($0.title).tag($0.id) }
                }
                .pickerStyle(.menu).tint(Theme.amber).frame(minHeight: 44)
                Text("Sleep timer").font(.headline).foregroundStyle(Theme.text)
                TimerPicker()
            }
            Card {
                Text("Volume").font(.headline).foregroundStyle(Theme.text)
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(Theme.muted).accessibilityHidden(true)
                    Slider(value: $store.volume, in: 0...1).tint(Theme.amber)
                        .frame(minHeight: 44).accessibilityLabel("App volume")
                        .accessibilityValue("\(Int(store.volume * 100)) percent")
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(Theme.muted).accessibilityHidden(true)
                }
            }
            downloads
            server
        }
        .onAppear { draft = store.serverAddress }
    }

    private var downloads: some View {
        Card {
            Text("Save for offline").font(.headline).foregroundStyle(Theme.text)
            Text("The five free sounds play offline when included in the app or saved here. Previews need a connection and are not kept for offline listening.")
                .font(.footnote).foregroundStyle(Theme.muted)
            let busy = !store.downloadingIDs.isEmpty
            Button { Task { await store.downloadAll() } } label: {
                Label(busy ? "Saving..." : "Save all five", systemImage: "arrow.down.circle")
            }
            .buttonStyle(AmberButtonStyle()).disabled(busy || store.offlineIDs.count == Soundscape.free.count)
            ForEach(Soundscape.free) { sound in
                let saved = store.offlineIDs.contains(sound.id)
                let bundled = store.bundledIDs.contains(sound.id)
                let loading = store.downloadingIDs.contains(sound.id)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(sound.title).foregroundStyle(Theme.text)
                            Text(loading ? "Saving" : bundled ? "Included in app · Offline ready" : saved ? "Saved on this iPhone" : "Not saved")
                                .font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        if loading { ProgressView().tint(Theme.amber) }
                        else if bundled {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(Theme.amber)
                                .accessibilityLabel("\(sound.title) is included in the app")
                        } else if saved {
                            Button("Remove") { store.removeDownload(sound) }
                                .buttonStyle(AmberButtonStyle(filled: false))
                                .accessibilityLabel("Remove \(sound.title) from this iPhone")
                        } else {
                            Button("Save") { Task { await store.download(sound) } }
                                .buttonStyle(AmberButtonStyle(filled: false))
                                .accessibilityLabel("Save \(sound.title)")
                        }
                    }
                    if let err = store.downloadErrors[sound.id] {
                        Text(err).font(.footnote).foregroundStyle(Theme.danger)
                    }
                }
            }
        }
    }

    private var server: some View {
        Card {
            Text("Audio server").font(.headline).foregroundStyle(Theme.text)
            TextField("https://example.com", text: $draft)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .keyboardType(.URL).textContentType(.URL)
                .padding(12).frame(minHeight: 44)
                .background(Theme.secondary, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.text)
                .onChange(of: draft) { _, _ in serverError = nil; saved = false }
            if let serverError { Text(serverError).font(.footnote).foregroundStyle(Theme.danger) }
            if saved { Text("Server saved.").font(.footnote).foregroundStyle(Theme.amber) }
            Button("Save server") {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                if AudioLibrary.serverURL(trimmed) == nil {
                    serverError = "Use a full HTTPS address, for example https://example.com, with no query or login details."
                } else {
                    store.serverAddress = trimmed; draft = trimmed; saved = true
                }
            }.buttonStyle(AmberButtonStyle())
        }
    }
}
