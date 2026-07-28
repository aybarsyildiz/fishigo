#!/usr/bin/env python3
"""Merges proxy/presence.json (GBIF/OBIS-derived) into
Fishigo/Resources/species.json, adding per-species `denizler` (sea presence —
the reliable signal) and `gozlem_aylari` (months with occurrence records —
OBSERVATION data, not fishing season). Idempotent; re-run after fetch.
"""
import json
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
species_path = root / "Fishigo/Resources/species.json"

with open(species_path) as f:
    doc = json.load(f)
with open(root / "proxy/presence.json") as f:
    presence = json.load(f)

for t in doc["turler"]:
    p = presence.get(t["id"], {})
    t["denizler"] = p.get("denizler", [])
    t["gozlem_aylari"] = p.get("aylar", [])

doc["_veri"] = ("denizler + gozlem_aylari: GBIF & OBIS gözlem kayıtlarından "
                "türetildi (proxy/fetch-presence.py). denizler = güvenilir "
                "sinyal; gozlem_aylari = bilimsel kayıt ayları, AV SEZONU "
                "DEĞİL (bağlayıcı sezon regulations.json'daki dönem yasağıdır).")

with open(species_path, "w") as f:
    json.dump(doc, f, ensure_ascii=False, indent=2)

filled = sum(1 for t in doc["turler"] if t["denizler"])
print(f"{filled}/{len(doc['turler'])} türe deniz verisi eklendi → species.json")
