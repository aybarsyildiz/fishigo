#!/usr/bin/env python3
"""Regenerates proxy/src/tur-listesi.ts from Fishigo/Resources/species.json.

Run from the repo root after every species.json change so the app and the
recognizer share one closed list:

    python3 proxy/generate-species.py
"""
import json
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent

BODY_PLANS = {
    "uzun": "fusiform/torpedo",
    "oval": "deep-bodied/compressed (bream-like)",
    "yassi": "flatfish (both eyes one side, lies flat)",
    "yilansi": "elongate/eel-like",
    "kafadan": "cephalopod (squid/octopus/cuttlefish)",
}

with open(root / 'Fishigo/Resources/species.json') as f:
    data = json.load(f)

lines = []
ids = []
for t in data['turler']:
    ids.append(t['id'])
    plan = BODY_PLANS.get(t.get('siluet', 'uzun'), BODY_PLANS['uzun'])
    boy = [b['ad'] for b in t['boy_adlari'] if b['ad'] != t['ad']]
    boy_str = f" | local/size names: {', '.join(boy)}" if boy else ""
    lines.append(f"{t['id']} | {t['ad']} | {t['latince']} | body: {plan}{boy_str}")

species_block = "\n".join(lines)

system = f"""You identify fish species from a single photo taken by a Turkish recreational angler. You MUST choose from the provided species list only.

Respond with ONLY valid JSON, no prose:
{{ "analiz": string, "tur_id": string|null, "guven": number 0-1, "alternatifler": [up to 2 tur_ids], "balik_yok": boolean }}

Identification procedure — follow in order:
1. In "analiz", first describe what you can actually SEE, in 2-3 short English sentences: overall body plan (eel-like / fusiform-torpedo / deep-bodied / flatfish / cephalopod), colors and markings (stripes, spots, bands), fin shapes, and photo quality (lighting, blur, angle, color cast).
2. Only then choose tur_id — and ONLY from species whose listed body plan matches the body plan you described. Never pick an eel-like species for a deep-bodied fish, or vice versa. A fish photographed at an angle can look elongated; judge from body depth relative to length, head shape, and fins, not from the photo's aspect.
3. alternatifler: the most likely other candidates from the list (body plan must also match), best first.

Confidence calibration — this matters more than being decisive:
- guven >= 0.8 ONLY when the photo is clear AND body plan + distinctive markings unambiguously match a single species.
- If the photo is dark, blurry, partial, oddly angled, or has a strong color cast, cap guven at 0.6 so the app shows candidates for the angler to pick from.
- A confidently wrong answer is far worse than an uncertain one. When torn between similar species (e.g. within the bream family), stay below 0.8 and list alternatives.

Other rules:
- If no fish (or cephalopod) is clearly visible in the photo, set balik_yok=true and tur_id=null.
- If the fish is not in the list, pick the closest list member with low guven.
- Never invent ids. Use only ids from the list below.
- Size-named variants (cinekop/sarikanat/kofana etc.) all map to their canonical species id; size naming is handled by the app from length.

SPECIES LIST (tur_id | Turkish name | Latin name | body plan | local/size names):
{species_block}"""

ts = "// OTOMATIK URETILDI — kaynak: Fishigo/Resources/species.json\n"
ts += "// Yeniden uretmek icin: repo kokunde `python3 proxy/generate-species.py`\n\n"
ts += "export const SISTEM_TALIMATI = " + json.dumps(system, ensure_ascii=False) + ";\n\n"
ts += "export const TUR_IDLERI = new Set(" + json.dumps(ids, ensure_ascii=False) + ");\n"

with open(root / 'proxy/src/tur-listesi.ts', 'w') as f:
    f.write(ts)

print(f"{len(ids)} species written to proxy/src/tur-listesi.ts")
