# Persona — Siri Personality Studio

A native SwiftUI iPhone app starter that lets a user choose an AI conversational style and invoke it with Siri Shortcuts / App Intents.

## Features
- SwiftUI personality library: Professional, Friendly Companion, Witty & Sarcastic, Technical Expert, Calm & Supportive, and optional Unfiltered 18+.
- Custom personality prompt editor.
- Configurable OpenAI-compatible chat-completions endpoint and model.
- API key stored in iOS Keychain.
- Siri App Intent: “Ask Persona” and “Talk to Persona”.
- Optional in-app speech output using iOS speech synthesis.

## Platform limitation
This app does **not** replace Siri's native system personality. Apple does not expose a public API for third-party apps to rewrite Siri's built-in responses. Siri can invoke Persona as an App Intent/shortcut, and Persona returns its own AI-generated response.

## Requirements
- macOS with Xcode 16 or later
- iOS 17 or later
- XcodeGen (`brew install xcodegen`)
- An API key for an OpenAI-compatible chat-completions endpoint

## Build
1. Run `xcodegen generate` in this directory.
2. Open `PersonaSiriStudio.xcodeproj`.
3. Select a simulator or iPhone, set your signing team, then Build & Run.
4. In Settings, enter the API endpoint, model, and API key.
5. Add the “Ask Persona” shortcut in Shortcuts or invoke it with Siri.

Default endpoint: `https://api.openai.com/v1/chat/completions`
Default model: `gpt-4o-mini`

## Privacy and production notes
- The API key is stored in Keychain on-device.
- Submitted prompts are sent to the configured AI provider.
- No account system, cloud sync, analytics, or hosted backend is included.
- For production, use a backend proxy rather than distributing provider credentials in an app, and add privacy disclosures, App Store metadata, age gating, and automated tests.
- The optional 18+ toggle is an acknowledgement gate, not age verification. It does not bypass Apple or AI-provider policies.

## Project structure
- `PersonaSiriStudio/PersonaApp.swift` — app entry
- `PersonaSiriStudio/Models.swift` — personalities and settings
- `PersonaSiriStudio/AIService.swift` — provider request
- `PersonaSiriStudio/KeychainStore.swift` — secure key storage
- `PersonaSiriStudio/ContentView.swift` — SwiftUI interface
- `PersonaSiriStudio/PersonaIntents.swift` — Siri App Intent

## Status
Development starter scaffold. It has not yet been built, signed, installed, or validated on a physical iPhone and is not App Store-ready.
