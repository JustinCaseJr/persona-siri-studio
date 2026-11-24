import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedID = UserDefaults.standard.string(forKey: PersonaSettings.selectedID) ?? "friendly"
    @State private var adultEnabled = UserDefaults.standard.bool(forKey: PersonaSettings.adultEnabled)
    @State private var customName = UserDefaults.standard.string(forKey: PersonaSettings.customName) ?? "My Personality"
    @State private var customPrompt = UserDefaults.standard.string(forKey: PersonaSettings.customPrompt) ?? "Be helpful, friendly, and concise."
    @State private var endpoint = UserDefaults.standard.string(forKey: PersonaSettings.endpoint) ?? "https://api.openai.com/v1/chat/completions"
    @State private var model = UserDefaults.standard.string(forKey: PersonaSettings.model) ?? "gpt-4o-mini"
    @State private var apiKey = KeychainStore.read() ?? ""
    @State private var voiceEnabled = UserDefaults.standard.bool(forKey: PersonaSettings.voiceEnabled)
    @State private var prompt = ""
    @State private var transcript: [AIService.Message] = []
    @State private var errorText = ""
    @State private var settingsMessage = ""
    @State private var busy = false
    @State private var showAdultConfirm = false
    private let synthesizer = AVSpeechSynthesizer()

    private var activePersona: Persona { PersonaSettings.selectedPersona }

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        Text("Choose how your assistant communicates.")
                            .foregroundStyle(.secondary)
                        ForEach(Persona.presets.filter { !$0.isAdult || adultEnabled }) { persona in
                            personaCard(persona)
                        }
                        if selectedID == "custom" { customEditor }
                        Button {
                            selectedID = "custom"
                            UserDefaults.standard.set("custom", forKey: PersonaSettings.selectedID)
                        } label: {
                            Label("Create your own personality", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
                .navigationTitle("Personalities")
            }
            .tabItem { Label("Personality", systemImage: "person.crop.circle") }

            NavigationStack {
                VStack(spacing: 0) {
                    if transcript.isEmpty {
                        ContentUnavailableView("Start a conversation", systemImage: "bubble.left.and.bubble.right",
                                               description: Text("Your conversation stays on this device while the app is open."))
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 14) {
                                    ForEach(Array(transcript.enumerated()), id: \.offset) { index, message in
                                        messageBubble(message)
                                            .id(index)
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: transcript.count) { _, count in
                                withAnimation { proxy.scrollTo(count - 1, anchor: .bottom) }
                            }
                        }
                    }
                    if !errorText.isEmpty {
                        Text(errorText).font(.footnote).foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                    }
                    composer
                }
                .navigationTitle(activePersona.name)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New chat", systemImage: "square.and.pencil") { transcript.removeAll(); errorText = "" }
                            .disabled(transcript.isEmpty || busy)
                    }
                }
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                Form {
                    Section("AI provider") {
                        TextField("HTTPS chat-completions endpoint", text: $endpoint)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                        TextField("Model", text: $model)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("API key", text: $apiKey)
                        Button("Save provider settings") { saveProviderSettings() }
                        Button("Remove saved API key", role: .destructive) {
                            KeychainStore.delete()
                            apiKey = ""
                            settingsMessage = "Saved API key removed from this device."
                        }
                        .disabled(KeychainStore.read() == nil)
                        if !settingsMessage.isEmpty {
                            Text(settingsMessage).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Section("Adult language") {
                        Toggle("Enable Unfiltered 18+ personality", isOn: Binding(
                            get: { adultEnabled },
                            set: { newValue in
                                if newValue { showAdultConfirm = true }
                                else {
                                    adultEnabled = false
                                    UserDefaults.standard.set(false, forKey: PersonaSettings.adultEnabled)
                                    if selectedID == "unfiltered" { select("friendly") }
                                }
                            }
                        ))
                        Text("Optional adult-language style with profanity and bold humor. This is an acknowledgement setting, not age verification, and does not bypass provider or platform policies.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("Voice") {
                        Toggle("Enable spoken replies", isOn: $voiceEnabled)
                            .onChange(of: voiceEnabled) { _, value in
                                UserDefaults.standard.set(value, forKey: PersonaSettings.voiceEnabled)
                            }
                        Text("Siri reads App Intent results using its own system voice settings. In-app speech uses the selected iOS speech voice.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Section("Siri") {
                        Label("Ask Persona", systemImage: "mic")
                        Text("Say “Hey Siri, Ask Persona” and provide your question. You can also add the Ask Persona shortcut in the Shortcuts app.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("Settings")
                .confirmationDialog("Enable adult-language mode?", isPresented: $showAdultConfirm) {
                    Button("I am 18 or older — Enable", role: .destructive) {
                        adultEnabled = true
                        UserDefaults.standard.set(true, forKey: PersonaSettings.adultEnabled)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This enables an optional personality that may use profanity and adult humor.")
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PERSONA").font(.caption.weight(.bold)).tracking(3).foregroundStyle(.tint)
            Text("Your assistant.\nYour personality.").font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message Persona…", text: $prompt, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await sendPrompt() }
            } label: {
                if busy { ProgressView() } else { Image(systemName: "arrow.up.circle.fill").font(.title) }
            }
            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || busy)
            .accessibilityLabel("Send message")
        }
        .padding()
        .background(.bar)
    }

    private func messageBubble(_ message: AIService.Message) -> some View {
        HStack {
            if message.role == "assistant" { Image(systemName: activePersona.symbol).foregroundStyle(.tint) }
            if message.role == "user" { Spacer(minLength: 36) }
            Text(message.content)
                .textSelection(.enabled)
                .padding(12)
                .background(message.role == "user" ? Color.accentColor.opacity(0.16) : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 16))
            if message.role == "assistant" {
                Button {
                    synthesizer.speak(AVSpeechUtterance(string: message.content))
                } label: {
                    Image(systemName: "speaker.wave.2")
                }
                .accessibilityLabel("Speak response")
            }
            if message.role == "assistant" { Spacer(minLength: 24) }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
    }

    private func personaCard(_ persona: Persona) -> some View {
        Button { select(persona.id) } label: {
            HStack(spacing: 14) {
                Image(systemName: persona.symbol)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(persona.name).font(.headline)
                        if persona.isAdult {
                            Text("18+").font(.caption.bold()).padding(.horizontal, 7).padding(.vertical, 3)
                                .background(.orange.opacity(0.18), in: Capsule())
                        }
                    }
                    Text(persona.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if selectedID == persona.id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                }
            }
            .padding()
            .background(selectedID == persona.id ? Color.accentColor.opacity(0.10) : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var customEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Personality name", text: $customName)
            Text("Describe how Persona should speak and behave.")
                .font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $customPrompt).frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary))
            Button("Save custom personality") {
                let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                let instructions = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !instructions.isEmpty else { return }
                UserDefaults.standard.set(name, forKey: PersonaSettings.customName)
                UserDefaults.standard.set(instructions, forKey: PersonaSettings.customPrompt)
                select("custom")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func select(_ id: String) {
        selectedID = id
        UserDefaults.standard.set(id, forKey: PersonaSettings.selectedID)
    }

    private func saveProviderSettings() {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmedEndpoint),
              components.scheme?.lowercased() == "https",
              components.host != nil,
              !trimmedModel.isEmpty else {
            settingsMessage = "Enter a valid HTTPS endpoint and model name."
            return
        }
        UserDefaults.standard.set(trimmedEndpoint, forKey: PersonaSettings.endpoint)
        UserDefaults.standard.set(trimmedModel, forKey: PersonaSettings.model)
        do {
            let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKey.isEmpty { try KeychainStore.save(trimmedKey) }
            settingsMessage = trimmedKey.isEmpty ? "Provider settings saved. Existing API key was unchanged." : "Provider settings and API key saved securely."
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sendPrompt() async {
        let outgoing = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !outgoing.isEmpty, !busy else { return }
        busy = true
        errorText = ""
        prompt = ""
        transcript.append(AIService.Message(role: "user", content: outgoing))
        defer { busy = false }
        do {
            let previousMessages = Array(transcript.dropLast())
            let response = try await AIService.reply(to: outgoing, persona: activePersona, history: previousMessages)
            transcript.append(AIService.Message(role: "assistant", content: response))
            if voiceEnabled { synthesizer.speak(AVSpeechUtterance(string: response)) }
        } catch {
            transcript.removeLast()
            prompt = outgoing
            errorText = error.localizedDescription
        }
    }
}
