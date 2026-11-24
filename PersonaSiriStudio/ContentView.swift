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
    @State private var answer = ""
    @State private var errorText = ""
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
                Form {
                    Section("Try your assistant") {
                        TextField("Ask anything…", text: $prompt, axis: .vertical)
                            .lineLimit(2...5)
                        Button {
                            Task { await sendPrompt() }
                        } label: {
                            if busy { ProgressView() } else { Label("Send to Persona", systemImage: "paperplane.fill") }
                        }
                        .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty || busy)
                        if !answer.isEmpty {
                            Text(answer).textSelection(.enabled)
                            Button("Speak response") {
                                synthesizer.speak(AVSpeechUtterance(string: answer))
                            }
                        }
                        if !errorText.isEmpty { Text(errorText).foregroundStyle(.red) }
                    }
                    Section("Current personality") {
                        Label(activePersona.name, systemImage: activePersona.symbol)
                    }
                }
                .navigationTitle("Conversation")
            }
            .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }

            NavigationStack {
                Form {
                    Section("AI provider") {
                        TextField("Chat completions endpoint", text: $endpoint)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        TextField("Model", text: $model)
                            .textInputAutocapitalization(.never)
                        SecureField("API key", text: $apiKey)
                        Button("Save provider settings") {
                            UserDefaults.standard.set(endpoint, forKey: PersonaSettings.endpoint)
                            UserDefaults.standard.set(model, forKey: PersonaSettings.model)
                            do { try KeychainStore.save(apiKey); errorText = "" }
                            catch { errorText = error.localizedDescription }
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
                    if !errorText.isEmpty { Text(errorText).foregroundStyle(.red) }
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
                UserDefaults.standard.set(customName, forKey: PersonaSettings.customName)
                UserDefaults.standard.set(customPrompt, forKey: PersonaSettings.customPrompt)
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

    @MainActor
    private func sendPrompt() async {
        busy = true
        errorText = ""
        answer = ""
        defer { busy = false }
        do {
            answer = try await AIService.reply(to: prompt, persona: activePersona)
            if voiceEnabled { synthesizer.speak(AVSpeechUtterance(string: answer)) }
        } catch {
            errorText = error.localizedDescription
        }
    }
}
