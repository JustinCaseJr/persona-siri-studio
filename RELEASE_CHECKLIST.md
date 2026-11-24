# Persona 1.0 — Release checklist

This checklist tracks work required before a public App Store release. A successful simulator build is not equivalent to a signed or device-tested release.

## Source and automated checks
- [x] Native SwiftUI application and iOS 17 deployment target
- [x] Siri App Intent and Shortcuts phrases
- [x] Keychain-backed provider API key storage
- [x] HTTPS-only provider endpoint validation
- [x] Bounded prompts and in-memory conversation context
- [x] Adult-style acknowledgement gate, including Siri invocation
- [x] Provider data-transfer disclosure
- [x] Initial VoiceOver labels for personality selection and chat messages
- [x] GitHub Actions simulator build and unit tests
- [x] Privacy manifest lint step passes in CI after this checklist update
- [ ] Review every VoiceOver screen with VoiceOver enabled

## Apple developer and device validation
- [ ] Set the final unique bundle identifier in `project.yml` (current development identifier: `com.persona.siripersonality`)
- [ ] Confirm Apple Developer Program membership and App Store Connect access
- [ ] Configure signing team, distribution certificate, and provisioning profile in Xcode
- [ ] Build and install on a physical iPhone running iOS 17 or later
- [ ] Verify first launch, tab navigation, personality selection, and custom personality editing
- [ ] Verify provider settings, Keychain save/replace/delete, invalid endpoint handling, network errors, and offline behavior
- [ ] Verify Siri phrases, Shortcuts discovery, denied permissions/settings, and response handoff on-device
- [ ] Verify in-app speech, interruption behavior, and system voice settings
- [ ] Test adult acknowledgement on and off, including Siri requests
- [ ] Test Dynamic Type, larger accessibility text, VoiceOver order, contrast, and keyboard focus
- [ ] Test app backgrounding, termination, relaunch, and transcript reset behavior

## App Store materials and compliance
- [ ] Create final app icon asset catalog and launch appearance
- [ ] Prepare screenshots for supported device sizes and an accurate app description
- [ ] Choose final age rating and complete App Store Connect content declarations
- [ ] Complete App Privacy questionnaire based on actual provider data flows and SDK inventory
- [ ] Publish a privacy policy explaining that prompts are sent to the user-configured AI provider
- [ ] Confirm provider terms, data retention, and API-key handling are appropriate for intended distribution
- [ ] Review Apple's current App Review Guidelines, especially user-generated content, AI content, and adult-language presentation
- [ ] Decide whether a backend proxy is required; do not ship a shared organization API key in a public client
- [ ] Archive, validate, upload to TestFlight, and complete external/internal beta testing
- [ ] Submit for App Review only after all checks above are complete

## Known product limitations
- Persona does not replace Apple's native Siri voice or personality; it is invoked as an App Intent/Shortcut.
- Siri requests are one-shot and do not share the in-app chat transcript.
- The app has no Persona-hosted account, cloud sync, or backend.
- The optional 18+ switch is an acknowledgement, not age verification, and does not override Apple or provider rules.
- Simulator CI cannot validate microphone/voice behavior, real Keychain behavior on a user's device, signing, or App Store acceptance.
