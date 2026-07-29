# App Store screenshots

Same method as ToneAmp: capture raw iPhone screenshots → frame them with
`tools/frame_screenshots.py` → upload the framed ones.

## Steps
1. Log a few catches first so the deks/map/stats look full (empty screens make
   weak marketing shots).
2. Capture these 6 screens **in this order**, save as `raw/01.png … raw/06.png`
   (on device: side button + volume up; or ⌘S in the simulator). Any iPhone
   size works — the script scales. A 6.9" device (16 Pro Max) is sharpest.

   | # | Screen | Caption it gets |
   |---|--------|-----------------|
   | 01 | Yakala — ana ekran (hook page, catch action + modüller) | Balığını fotoğrafla, türü anında öğren. |
   | 02 | Kart açılışı (bir yakalayışın tür kartı / reveal) | Her yakalayış, bir koleksiyon kartı. |
   | 03 | Balıkdeks (tür ızgarası, siluetler + toplanmışlar) | 70 tür seni bekliyor. Balıkdeks'ini doldur. |
   | 04 | Kart / detay — boy + boy-limiti/sezon rozeti görünür | Boy ve sezon kuralları, tek bakışta. |
   | 05 | Defter → Harita (özel ısı haritası) | Yakaladığın nokta sende kalır. |
   | 06 | Koşullar sayfası veya "Bugün ne tutulur" | Bugün ne tutulur? Koşullar hazır. |

3. Run:
   ```
   python3 tools/frame_screenshots.py
   ```
4. Upload `framed/*.png` to App Store Connect → the **iPhone 6.9"** screenshot
   slot. That one set covers all iPhone sizes.

## Notes
- Captions live in `tools/frame_screenshots.py` (`CAPTIONS`) — edit freely.
- `raw/01.png` + `framed/01.png` here are a **sample** (onboarding screen) so you
  can see the output; replace them with the real captures above.
- Needs Pillow: `pip install pillow`.
