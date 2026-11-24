# Persona — Siri Personality Studio

A native SwiftUI iPhone app that provides selectable AI conversational styles and can be invoked through Siri Shortcuts / App Intents.

## Included
- Personality presets: Professional, Friendly Companion, Witty & Sarcastic, Technical Expert, Calm & Supportive, and optional Unfiltered 18+.
- Custom personality prompt editor.
- Multi-turn in-app chat with the most recent 20 turns included as context.
- Configurable OpenAI-compatible chat-completions endpoint and model.
- API key stored in iOS Keychain.
- Siri App Intent: “Ask Persona” and “Talk to Persona”.
- In-app speech synthesis and spoken-reply preference.
- HTTPS-only endpoint validation and basic response/error handling.
- Privacy manifest, unit-test target, and GitHub Actions build/test workflow.

## Important Siri limitation
This app does **not** replace Siri's native system personality. Apple does not expose a public API for third-party apps to rewrite Siri's built-in responses. Siri invokes Persona as an App Intent/shortcut; Persona returns its own AI-generated response.

## Requirements
- macOS with Xcode 16 or later
- iOS 17 or later
- XcodeGen (`brew install xcodegen`)
- An API key for an OpenAI-compatible chat-completions endpoint

## Build on a Mac
1. Clone this repository.
2. Run `brew install xcodegen` if needed.
3. Run `xcodegen generate` in the repository directory.
4. Open `PersonaSiriStudio.xcodeproj`.
5. Select an iPhone simulator or connected iPhone and configure your Apple development signing team.
6. Build and run.
7. In Settings, enter your provider endpoint, model, and API key.
8. Select a personality, then use the Chat tab or add the “Ask Persona” shortcut in Shortcuts.

Default endpoint: `https://api.openai.com/v1/chat/completions`
Default model: `gpt-4o-mini`

## Siri setup
After installing the app, open Shortcuts and look for the Ask Persona action. Siri phrase availability and invocation behavior depend on iOS version, device settings, and the user's configured Siri language.

## Privacy and production readiness
- The API key is stored in the iOS Keychain.
- Chat prompts and the recent conversation context are sent to the AI provider configured by the user.
- The current conversation is held in app memory only; it is not synced to a Persona server.
- No account system, cloud sync, analytics, or hosted backend is included.
- A client-side API key is extractable from a determined attacker/device owner. For a public production release, use an authenticated backend proxy and per-user rate limits instead of shipping a shared provider key.
- The optional 18+ switch is an acknowledgement gate, not age verification. It does not bypass Apple or AI-provider policies.
- App Store privacy disclosures, age-rating review, accessibility review, signing, icon assets, and real-device testing remain required before release.

## Project structure
- `PersonaSiriStudio/PersonaApp.swift` — app entry
- `PersonaSiriStudio/Models.swift` — personalities and settings
- `PersonaSiriStudio/AIService.swift` — provider request and conversation context
- `PersonaSiriStudio/KeychainStore.swift` — secure key storage
- `PersonaSiriStudio/ContentView.swift` — SwiftUI interface
- `PersonaSiriStudio/PersonaIntents.swift` — Siri App Intent
- `PersonaSiriStudio/PrivacyInfo.xcprivacy` — privacy manifest
- `Tests/PersonaSiriStudioTests` — unit tests
- `.github/workflows/ios-ci.yml` — macOS CI build and test workflow

## Verification status
The source and project configuration are committed, but this environment does not provide Xcode or an iOS Simulator. The app has **not yet been compiled, signed, installed, or tested on a physical iPhone**. GitHub Actions is configured to perform an Xcode build and unit tests on pushes and pull requests; check the Actions tab for its first run.
