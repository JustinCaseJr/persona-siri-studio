# Persona — Personality Studio (Web)

Persona is a responsive, browser-based AI personality studio. It works on iPhone, iPad, and desktop browsers without Xcode, an iOS installation, or an Apple Developer account.

## Features
- Six selectable personalities: Professional, Friendly Companion, Witty & Sarcastic, Technical Expert, Calm & Supportive, and optional Unfiltered 18+.
- Custom personality editor with a 4,000-character instruction limit.
- Multi-turn chat with bounded recent context (40 messages / 24,000 characters).
- Optional OpenAI-compatible Chat Completions endpoint and model.
- Free on-device AI mode powered by WebLLM/WebGPU; no API key, account, backend, or per-request inference charge. The model is downloaded to the browser on first use and cached locally.
- Settings includes a **Test OpenAI connection** action to validate the configured endpoint, model, and key before chatting.
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

## Use free local AI (no API credits)
1. Open Settings and choose **Free local AI (runs on this device)**.
2. Select **Load free local model**. Persona downloads the compact Qwen2.5 0.5B model (approximately 1 GB) from the model host and caches it in the browser.
3. Wait for the model status to say Ready, then start a conversation.
4. Messages are processed on your device. After the initial model download, inference does not require an AI API or send prompts to a model provider.

Local mode requires WebGPU and enough device memory/storage. If the browser cannot provide WebGPU or the GPU runs out of memory, use a compatible desktop browser/device. Model quality and speed are lower than larger hosted models. The initial download uses internet bandwidth but has no Persona or model API charge.

## Configure the optional OpenAI API
1. Open Settings and choose **OpenAI API**.
2. Enter an HTTPS OpenAI-compatible Chat Completions endpoint.
3. Enter a model name and your own API key.
4. Save the connection and select **Test OpenAI connection** to check it.
5. Start a conversation after the test succeeds. OpenAI API billing is separate from ChatGPT subscriptions.

Default endpoint: `https://api.openai.com/v1/chat/completions`

Default model: `gpt-4o-mini`

**Browser compatibility note:** The configured cloud provider must permit requests from the website's origin using CORS. Some providers block browser-origin requests. If so, a server-side proxy is required; this repository intentionally does not provision one or incur hosting/API costs.

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
