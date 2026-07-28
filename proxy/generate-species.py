#!/usr/bin/env python3
"""Regenerates proxy/src/tur-listesi.ts from Fishigo/Resources/species.json.

Run from the repo root after every species.json change so the app and the
recognizer share one closed list:

    python3 proxy/generate-species.py
"""
import json
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent

with open(root / 'Fishigo/Resources/species.json') as f:
    data = json.load(f)

lines = []
ids = []
for t in data['turler']:
    ids.append(t['id'])
    boy = [b['ad'] for b in t['boy_adlari'] if b['ad'] != t['ad']]
    boy_str = f" | yerel/boy adlari: {', '.join(boy)}" if boy else ""
    lines.append(f"{t['id']} | {t['ad']} | {t['latince']}{boy_str}")

species_block = "\n".join(lines)

system = f"""You identify fish species from a single photo taken by a Turkish recreational angler. You MUST choose from the provided species list only.

Respond with ONLY valid JSON, no prose:
{{ "tur_id": string|null, "guven": number 0-1, "alternatifler": [up to 2 tur_ids], "balik_yok": boolean }}

Rules:
- If no fish (or cephalopod) is clearly visible in the photo, set balik_yok=true and tur_id=null.
- If the fish is not in the list, pick the closest list member with low guven.
- Never invent ids. Use only ids from the list below.
- Size-named variants (cinekop/sarikanat/kofana etc.) all map to their canonical species id; size naming is handled by the app from length.
- guven reflects your true confidence: 0.9+ only when the species is unmistakable.
- alternatifler: the most likely other candidates from the list when guven < 0.8, best first.

SPECIES LIST (tur_id | Turkish name | Latin name | local/size names):
{species_block}"""

ts = "// OTOMATIK URETILDI — kaynak: Fishigo/Resources/species.json\n"
ts += "// Yeniden uretmek icin: repo kokunde `python3 proxy/generate-species.py`\n\n"
ts += "export const SISTEM_TALIMATI = " + json.dumps(system, ensure_ascii=False) + ";\n\n"
ts += "export const TUR_IDLERI = new Set(" + json.dumps(ids, ensure_ascii=False) + ");\n"

with open(root / 'proxy/src/tur-listesi.ts', 'w') as f:
    f.write(ts)

print(f"{len(ids)} species written to proxy/src/tur-listesi.ts")
