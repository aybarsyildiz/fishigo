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
- [x] M5 Cloudflare Worker proxy + real recognition + quota + corrections log
- [x] M6 regulations loader + legality states + disclaimer (values = SAMPLE; owner fills)
- [x] M7 weather snapshot + condition score + sefer serisi streak + notification
- [~] M8 IN PROGRESS: sound done ✓; onboarding done ✓ (earlier); remaining →
      Reduce Motion full audit, VoiceOver/Dynamic Type, corrections launch sweep,
      settings screen, App Store metadata + screenshots. Owner-only: real
      regulation values, rarity/threshold tuning, signing team, bundle id.

## Proxy (M5)

- Worker `fishigo-tanima` at https://fishigo-tanima.toneamp.workers.dev
  (`proxy/`, wrangler.jsonc, KV binding KOTA id 474e422b52064b47a137cbc3605e5ffc).
- Secret: `cd proxy && npx wrangler secret put ANTHROPIC_API_KEY` (owner's
  terminal only — never in repo/chat). `.dev.vars` (gitignored) for local dev.
- POST /tanima {gorsel: b64 jpeg} + x-cihaz header → §4 JSON + kalan_hak;
  429 when the 10/month KV quota (kota:<cihaz>:<YYYY-MM>) is spent. Structured
  outputs (json_schema) guarantee parseable §4 JSON; server validates ids
  against the closed list (never invent). POST /duzeltme stores corrections.
- species prompt is GENERATED: `python3 proxy/generate-species.py` after every
  species.json change (single source of truth).
- MODEL = claude-sonnet-4-6 (constant in index.ts). Haiku 4.5 confidently
  misread body plans on hard photos (real mırmır at night → "müren 0.85");
  prompt fixes lowered confidence but not the wrong perception; Sonnet read
  the correct bream family on the same image. Cost ≈ $0.013/recognition
  (~3.3k in @$3/MTok + ~130 out @$15/MTok) → ≤ $0.13/free-user/month.
- Prompt structure (generate-species.py): per-species BODY PLAN from siluet,
  see-first required "analiz" field (described before naming; logged
  server-side, stripped from client response), and confidence calibration
  (≥0.8 only clear+unambiguous; dark/blurry/angled → cap 0.6 so the UI shows
  candidate chips). Wrong-but-confident is the failure mode to prevent.
- Prompt caching: cache_control set but INERT — prompt ~1.7k tokens vs
  Sonnet 4.6 cache floor 2048. Engages automatically if the prompt grows.
- Accuracy testing: reproduce cases by POSTing a JPEG to /tanima with a test
  x-cihaz id (each run burns that test id's quota, not the owner's phone).
  Owner corrections via DEĞİŞTİR feed the corrections dataset.
- Client: ProxySpeciesRecognizer default; MockSpeciesRecognizer kept for dev
  (swap in AppModel). Quota counter via @AppStorage("kalanTanima"); 429 →
  PaywallStubView (product ids TODO: fishigo.pro.aylik/yillik); network error →
  NetworkErrorView. Both offer manual species pick — logging is never blocked.
- Corrections: CorrectionEntry (photo SHA256 + suggested + corrected), local
  first, best-effort upload; launch sweep TODO(M8).
- M6 regulations: `proxy/regulations.json` is the SOURCE (edit + `npm run
  deploy`; app pulls via GET /kurallar with ETag). `Fishigo/Resources/
  regulations.json` is the bundled offline/first-launch copy — keep in sync.
  Current content is a SCHEMA SAMPLE ('ornek-tur' only) → every real species
  shows "kural bilgisi yok" until the owner enters tebliğ values. Closed-season
  ranges are MM-DD and may wrap the year end; season outranks size limit.

## M7 notes

- Weather snapshot: Open-Meteo forecast API fetched best-effort right after
  save (like province); fills the reserved CatchRecord columns. Marine API
  gives wave height for the score only.
- Condition score v1: region = most recent LOCATED catch (simplification —
  "saved regions" can come later). Weights in ConditionStore.hesapla are
  PLACEHOLDER (wind/wave/pressure/solunar/senin-saatin). Phrase is always
  "Koşullar uygun/orta/zayıf" — NEVER a fish promise; disclaimers in the sheet.
- Solunar: lunar-lag approximation (transit ≈ solar noon + age×50.47 min),
  ±30-40 dk. Meeus upgrade optional later (documented in Solunar.swift).
- Sefer serisi: weekly; outing = CatchRecord OR EmptyTrip. Streak survives the
  current week being empty until the week actually passes. "BOŞ DÖNDÜM" bar on
  the hook page (warning haptic, never error; copy never shames).
- Daily notice: opt-in toggle inside KosullarSheet, visible only after first
  catch (§9); one repeating local notification 07:30, static invite copy
  (score is computed on open — BGTask real-score version is v1.x).
- Hook shelf final: [deks, son yakalayış] / [sefer serisi, rekor] / koşullar
  (wide) / boş-döndüm bar. Stats wind rose uses the 8 Turkish wind names
  (RuzgarYonu); insight prefers wind habit ("En çok lodosta tutuyorsun") once
  ≥3 weather-tagged records exist.

## Data enrichment (GBIF/OBIS + SST)

- Per-species sea presence + observation months baked into species.json
  (`denizler`, `gozlem_aylari`). Pipeline: `python3 proxy/fetch-presence.py`
  (GBIF per-sea WKT + month facet, OBIS cross-check → proxy/presence.json with
  counts as evidence) then `python3 proxy/merge-presence.py`. 64/67 have sea
  data; 3 sparse (granyoz, tombik, öksüz) left empty → "veri yok" in UI.
- HONESTY: `denizler` = reliable presence signal. `gozlem_aylari` = scientific
  OBSERVATION records (when researchers sampled), NOT fishing season — labelled
  "AV SEZONU DEĞİL" in RegionPanel; binding season stays the regulations.json
  closed period. Never phrase presence as a fish promise.
- Occurrence DBs are sparse for Turkish seas — treat as a starting signal the
  owner refines with local knowledge. Public/community heatmap stays OUT; the
  owner's OWN Defter map is a private heatmap (stacked muhur glow).
- SST: Open-Meteo marine `sea_surface_temperature` added to WeatherService.marine
  → catch snapshot (CatchRecord.sstC) + condition score factor (14–22°C sweet
  spot, placeholder band). No API key. Balıkdeks detail shows the RegionPanel.

## M8 / additions

- Logo v2: "specimen seal" — muhur rubber-stamp ring with a fish carved in
  negative space, ties to the İLK YAKALAYIŞ ceremony. Generator kept at
  Fishigo/Resources/AppIcon-generator.swift.txt; render + copy to AppIcon.png.
- Sound (§7): 3 placeholder WAVs in Resources/Sounds (make-sounds.py, stdlib) —
  tik (reel-click → ruler/cascade), damga (ink-thunk → stamp), yeni-tur
  (brass sting → new species/line complete). Ses.swift plays via AVAudioPlayer,
  category .ambient (silent switch respected; TRADEOFF: no ducking under music —
  chose the switch). Optional via @AppStorage("sesAcik"); toggle in KosullarSheet.
  TODO(sound): replace placeholders with recorded foley.
- Kova modu (bucket mode): whole-catch photo → proxy /coklu → editable species
  list → bulk save. NOT ceremonial (single-catch flow keeps its reveal). Records
  saved with length 0 ("BOY YOK" in log), note "Kova modu", shared photo, one
  weather stamp for the batch. Entry: dashed button on the catch screen.
- LEADERBOARD: NOT built. "leaderboards" are a permanent OUT; ranking users
  needs a backend (§3 forbids) and breaks NOT-a-social-network + spots-sacred.
  Channel that energy into single-player hooks instead (achievements, monthly
  recap card, "bugün ne tutulur" region suggestions) — proposed, await owner.

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
