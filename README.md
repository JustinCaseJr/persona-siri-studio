# Persona — Personality Studio (Web)

Persona is a responsive, browser-based AI personality studio. It works on iPhone, iPad, and desktop browsers without Xcode, an iOS installation, or an Apple Developer account.

## Features
- Six selectable personalities: Professional, Friendly Companion, Witty & Sarcastic, Technical Expert, Calm & Supportive, and optional Unfiltered 18+.
- Custom personality editor with a 4,000-character instruction limit.
- Multi-turn chat with bounded recent context (40 messages / 24,000 characters).
- Configurable OpenAI-compatible Chat Completions endpoint and model.
- Optional browser speech synthesis for spoken replies.
- Responsive mobile and desktop interface.
- Preferences and provider key stored locally in the current browser.
- No Persona application server, account system, analytics, cloud sync, or paid infrastructure required by this repository.

## Run locally
No build step or package installation is required for the app itself. Node.js 22 or later is only needed for unit tests.

```bash
git clone https://github.com/JustinCaseJr/persona-siri-studio.git
cd persona-siri-studio
python3 -m http.server 8080
```

Open http://localhost:8080. Do not open index.html as a file URL; browser modules and network requests require an HTTP origin.

Run tests with `npm test`.

## Configure an AI provider
1. Open Settings.
2. Enter an HTTPS OpenAI-compatible Chat Completions endpoint.
3. Enter a model name and your own API key.
4. Save the connection and start a conversation.

Default endpoint: `https://api.openai.com/v1/chat/completions`

Default model: `gpt-4o-mini`

**Browser compatibility note:** The configured provider must permit requests from the website's origin using CORS. Some providers block browser-origin requests. If so, a server-side proxy is required; this repository intentionally does not provision one or incur hosting/API costs.

## Security and privacy
- The API key is stored in browser local storage. This is convenient for a personal prototype, but it is not a secure vault. Anyone with access to the browser profile or a successful same-origin script injection may be able to retrieve it.
- Never place a shared organization key or a high-privilege production key in a public/shared browser.
- Chat history exists only in page memory and is cleared when the page is reloaded or New chat is selected.
- When you send a prompt, the browser sends the selected personality instructions, bounded recent conversation, and current message directly to the AI provider you configured.
- Persona does not operate a backend or collect analytics in this version. Provider data handling, retention, billing, and terms are governed by that provider.
- The optional adult-language toggle is an acknowledgement gate, not age verification. It does not bypass provider rules or applicable law.

## Siri limitation
This web app can be opened and used alongside Siri, including on iPhone. It cannot replace Apple's native Siri, register the former iOS App Intent, or change Siri's built-in personality. Browser and iOS platform restrictions prevent a website from modifying the system assistant.

## Hosting
The app is static and can be hosted on a static web host. GitHub Actions runs unit tests on pushes and pull requests. To publish with GitHub Pages, enable Pages for the repository and select GitHub Actions as the deployment source. No paid backend or Railway service is needed.

## Project structure
- `index.html` — application shell and accessible UI structure
- `styles.css` — responsive design
- `src/app.js` — browser interactions, chat, settings, and speech
- `src/core.js` — presets, endpoint validation, and context bounds
- `tests/core.test.js` — unit tests
- `.github/workflows/web-ci.yml` — web test workflow

## Project status
The repository has been converted to a static web implementation. Browser CI and real-provider browser testing must pass before calling the web release verified.
