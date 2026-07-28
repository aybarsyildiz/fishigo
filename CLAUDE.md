# Fishigo — Turkish fishing-log iOS app

Türkiye'nin balıkçılık yoldaşı: photograph a catch → species recognized →
legality shown → collectible specimen card in the "Balıkdeks". Pokémon-collection
joy × Duolingo responsiveness, skinned as a 1930s naturalist specimen archive.
NOT social, NOT spot-sharing ("Noktan sende kalır"). All UI text Turkish.

**Hard deadline: bluefish (lüfer) season opens September 2026.** Scope is ruthless.

## Build

```sh
xcodebuild build -project Fishigo.xcodeproj -target Fishigo -sdk iphonesimulator -configuration Debug
```

Project uses Xcode 16+ folder-synchronized groups (`objectVersion 77`): any file
added under `Fishigo/` is picked up automatically — never edit the pbxproj to add files.
iOS 17+, SwiftUI, Swift 5 language mode. iPhone only, portrait only.

## Architecture (planned)

- MVVM-ish, lightweight observable stores. SwiftData local-first; CloudKit private DB sync.
- LLM species recognition (claude-haiku-4-5) ONLY via a serverless proxy (M5) — API key
  never in the client; 10 recognitions/month free quota enforced server-side.
  Proxy prompt-caching note: Haiku 4.5 min cacheable prefix is 4096 tokens — pad the
  species-list system prompt above that or caching silently won't engage.
- Legality is 100% on-device deterministic from regulations.json (bundled + remote,
  ETag-cached). The LLM NEVER answers legality. Values populated by owner; never fabricate.
- Weather: Open-Meteo forecast+marine (no key). Solunar computed on device.
- Rive for ceremonies later; every ceremony first implemented in SwiftUI behind a
  protocol so Rive can replace it without touching callers.

## Layout

- `Fishigo/App/` — app entry, root tab scaffold
- `Fishigo/DesignSystem/` — `Ink` (color tokens), `Typo` (fonts, runtime-registered)
- `Fishigo/FeelKit/` — `Motion` (timing constants, Reduce Motion), `Feel` (haptic map)
- `Fishigo/Resources/` — assets, `Localizable.xcstrings` (sourceLanguage=tr), `Fonts/`

## Non-negotiables (from the brief)

- §6 design: flat inks + paper only. No neon, no gradients, no glassmorphism, no
  iOS-blue. `Ink.muhur` (stamp red) max once per screen. Fraunces 900 display /
  italic Latin; IBM Plex Mono data.
- §7 feel: every input acknowledged <100 ms (visual + haptic via `Feel`); micro
  springs 0.3–0.45/0.7–0.85; suspense beat 300–500 ms AFTER recognition result;
  numbers count up, never appear; Reduce Motion → crossfade, haptics stay; empty
  catch is warning haptic, NEVER error. All timing/haptics go through FeelKit —
  no inline generators or magic durations at call sites.
- Privacy: locations private by default; share shows province (il) only. Copy never
  shames a fishless day. No loot/paid-randomness mechanics, ever.
- Ask before adding ANY scope beyond the brief. Prefer the simpler option and flag it.

## Milestones

- [x] M0 scaffold, tokens, FeelKit
- [x] M1 catch flow with MOCKED recognition (full anticipation→reveal→stamp choreography)
- [x] M2 SwiftData models + log + private map + stats v1 (CloudKit sync deferred — needs team/entitlements)
- [x] M3 deks grid + silhouettes + cascade + evolution lines + hook page v1
- [x] M4 specimen card renderer + 9:16 export + share sheet (video-ready via progress param)
- [ ] M5 proxy (Cloud Function/Worker) + real recognition + quota + corrections log
- [ ] M6 regulations loader + legality states + disclaimer
- [ ] M7 weather snapshot + condition score + sefer serisi streak + notification
- [ ] M8 polish pass, Reduce Motion audit, empty states, onboarding, ASO stubs

## Decisions log

- Project name **Fishigo** (brief header) — brief body once says "Fishing"; assumed typo.
- Hand-written pbxproj with synchronized folder group instead of XcodeGen (not installed;
  zero-dependency, files auto-sync).
- Color tokens in code (`Ink`), not asset catalog — single source, trivially diffable.
- Fonts: Fraunces variable + IBM Plex Mono statics downloaded from google/fonts (OFL,
  licenses bundled in `Resources/Fonts/`). Registered at runtime (`Typo.registerBundledFonts`)
  → no UIAppFonts Info.plist entry needed. System serif/mono fallbacks if lookup fails.
  TODO: verify Turkish glyph rendering + Fraunces optical size on device.
- AccentColor = kagit (#EDE5D1); muhur is reserved for THE accent moment per screen.
- App forced dark (`preferredColorScheme(.dark)`) — archive has no light chrome.
- Bundle id placeholder `com.netnucleus.fishigo` — confirm before App Store work.
- Repo lives at github.com:aybarsyildiz/fishigo (main). Commit per milestone.
- M1: legality UI states (enum + chip + disclaimer) pulled forward from M6 with a
  stub checker returning `bilgiYok` — M6 becomes pure data plumbing. Recognition is
  `MockSpeciesRecognizer` cycling 4 fixtures (confident lüfer / low-conf istavrit /
  balık yok / epik kalkan) with a 1.7 s delay to exercise the anticipation state.
- M1: `species.json` is a 10-species SAMPLE with PLACEHOLDER thresholds/rarities
  (marked in the file); full ~70 list lands with M3.
- M1: camera = UIImagePickerController (upgrade to AVFoundation only if needed);
  gallery = PhotosPicker (no permission prompt). Photos downscaled through
  `ImagePipeline` (1024 px / JPEG 0.7) — same bytes go to recognizer and log.
- UI principle (owner feedback after M1): archival ARTIFACTS (cards, frames,
  stamps, specimen plates) stay square-ruled; INTERACTIVE controls (buttons,
  chips, fields) use continuous rounded corners (9–12 pt) so they read as
  tappable. Full UI review happens at M8 — collect owner nits until then.
- M2: `CatchRecord` is SwiftData `@Model` (photo via `.externalStorage`);
  weather columns already exist as optionals so M7 needs no migration.
  Location = one-shot CoreLocation fix started at photo pick, awaited max 3 s at
  save — a catch is never blocked by GPS. Defter tab = KAYITLAR/HARİTA/İSTATİSTİK
  under a rule bar; list uses @Query, flow writes via CatchLog (ModelContext).
- HOOK PAGE (owner: "main page is the most important — it's the HOOK"): Yakala
  tab is an archive desk (procedural ChartFragment background, catch plate,
  module shelf). Grows per milestone: M3 shipped deks-progress + last-catch
  modules; M7 MUST add sefer serisi + koşullar modules to the same shelf; M8
  polishes. Do not let the main page stay static.
- App icon: generated programmatically (scratchpad CoreGraphics script → 1024px
  PNG in AppIcon.appiconset) — paper fish on ink, double-rule frame, muhur
  bobber. Regenerate by editing the script if the design changes.
- Onboarding: 3 pages, guide fish swims between pages with tail-stroke haptics,
  stamp demo on page 2. Gated by @AppStorage("karsilamaGoruldu"). NO permission
  prompts in onboarding (§9 — they stay in-context at first catch).
- Hook density (owner: "more crowded"): ledger head with live record counts,
  ChartFragment `ornaments` mode (compass rose + extra soundings), 2×2 module
  shelf (deks / son yakalayış / rekor / bu ay). M7 swaps "bu ay" for the real
  sefer serisi module and adds koşullar.
- M3: species.json now has 69 real species (rarity + thresholds still
  PLACEHOLDER). No per-species artwork: 5 generic body-type silhouettes
  (`siluet`: uzun/oval/yassi/yilansi/kafadan) drawn as Paths — dotted stroke =
  uncaught engraving, solid fill = inked/caught. Deks tiles cascade-flip on
  first open with capped ticks. Evolution lines: 4 chains (lüfer, palamut,
  levrek, istavrit); band = any catch whose length falls in it; completing a
  chain → SERİ TAMAMLANDI banner + ceremony haptic on the saved screen.
