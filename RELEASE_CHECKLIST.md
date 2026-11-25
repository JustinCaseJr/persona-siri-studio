# Persona Web — Release checklist

## Web implementation
- [x] Responsive browser UI for desktop and mobile
- [x] Six selectable personality presets
- [x] Custom personality editor (4,000-character cap)
- [x] Multi-turn chat and bounded context
- [x] HTTPS endpoint validation
- [x] Browser speech synthesis
- [x] Adult-language acknowledgement gate
- [x] Provider/privacy disclosures
- [x] Automated unit tests and web CI workflow
- [ ] Verify GitHub Actions web workflow passes on the latest commit
- [ ] Test in Safari on a physical iPhone and desktop browsers
- [ ] Test provider requests against a real account and verify CORS support
- [ ] Test storage behavior in private browsing and storage-restricted environments
- [ ] Add a published privacy policy and final contact/support details before public launch

## Publishing
- [ ] Enable GitHub Pages using GitHub Actions as the deployment source, or choose another static host
- [ ] Confirm the live HTTPS URL and test mobile layout on that URL
- [ ] Add a custom domain only if desired
- [ ] Review provider terms, privacy, billing, and API key restrictions

## Known limitations
- A browser app cannot replace or modify Apple's native Siri.
- Provider browser CORS restrictions may prevent direct API calls; a server-side proxy would then be required.
- The API key is stored in local browser storage, not a secure vault. This build is intended for personal use/prototyping, not a public multi-user production service.
- Chat history is in memory only and disappears on reload.
- The 18+ setting is an acknowledgement, not age verification or a policy override.
- No paid hosting, backend, Railway resources, or subscription is created by this repository change.
