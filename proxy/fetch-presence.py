#!/usr/bin/env python3
"""Fetches per-species sea-basin presence + monthly occurrence distribution for
Turkish waters from GBIF (cross-checked against OBIS) and writes
proxy/presence.json.

Data is genuinely sparse for Turkish seas in these open databases, so treat
the result as a starting signal the owner refines with local knowledge — the
counts travel with each entry as evidence. Re-run any time:

    python3 proxy/fetch-presence.py

Then merge into species.json with:  python3 proxy/merge-presence.py
"""
import json
import pathlib
import time
import urllib.parse
import urllib.request

root = pathlib.Path(__file__).resolve().parent.parent

# Turkish sea polygons (WKT, lon lat). Deliberately generous at the margins —
# this is basin-level presence, not spot data.
SEAS = {
    "karadeniz": "POLYGON((27.5 41,42 41,42 43,27.5 43,27.5 41))",
    "marmara": "POLYGON((26.3 40.3,30 40.3,30 41.2,26.3 41.2,26.3 40.3))",
    "ege": "POLYGON((25 35.8,27.5 35.8,27.5 40.5,25 40.5,25 35.8))",
    "akdeniz": "POLYGON((27.5 35.8,36.5 35.8,36.5 37,27.5 37,27.5 35.8))",
}
TURKISH_BBOX = "POLYGON((22 35,42 35,42 43,22 43,22 35))"
# Combined GBIF+OBIS count at/above this marks the sea "present" (filters strays).
PRESENCE_THRESHOLD = 2


def get_json(url):
    try:
        with urllib.request.urlopen(url, timeout=25) as resp:
            return json.load(resp)
    except Exception as exc:
        print(f"    ! {exc}")
        return None


def gbif_count(latin, geometry):
    url = ("https://api.gbif.org/v1/occurrence/search?scientificName="
           + urllib.parse.quote(latin)
           + "&geometry=" + urllib.parse.quote(geometry) + "&limit=0")
    d = get_json(url)
    return d.get("count", 0) if d else 0


def gbif_months(latin, geometry):
    url = ("https://api.gbif.org/v1/occurrence/search?scientificName="
           + urllib.parse.quote(latin)
           + "&geometry=" + urllib.parse.quote(geometry)
           + "&facet=month&facetLimit=12&limit=0")
    d = get_json(url)
    if not d or not d.get("facets"):
        return {}
    return {int(c["name"]): c["count"] for c in d["facets"][0]["counts"] if c["name"]}


def obis_count(latin, geometry):
    url = ("https://api.obis.org/v3/occurrence?scientificname="
           + urllib.parse.quote(latin)
           + "&geometry=" + urllib.parse.quote(geometry) + "&size=0")
    d = get_json(url)
    return d.get("total", 0) if d else 0


with open(root / "Fishigo/Resources/species.json") as f:
    species = json.load(f)["turler"]

out = {}
for i, t in enumerate(species, 1):
    latin = t["latince"]
    print(f"[{i}/{len(species)}] {t['ad']} ({latin})")

    per_sea = {}
    denizler = []
    for sea, wkt in SEAS.items():
        g = gbif_count(latin, wkt)
        time.sleep(0.12)
        o = obis_count(latin, wkt)
        time.sleep(0.12)
        total = g + o
        per_sea[sea] = {"gbif": g, "obis": o}
        if total >= PRESENCE_THRESHOLD:
            denizler.append(sea)

    months = gbif_months(latin, TURKISH_BBOX)
    time.sleep(0.12)
    total_month_records = sum(months.values())
    aylar = sorted(m for m, c in months.items() if c >= 1) if total_month_records >= 8 else []

    out[t["id"]] = {
        "denizler": denizler,
        "aylar": aylar,
        "kanit": {"per_sea": per_sea, "ay_kayit": total_month_records},
    }
    print(f"    denizler={denizler} aylar={aylar} (ay kaydı={total_month_records})")

with open(root / "proxy/presence.json", "w") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)

covered = sum(1 for v in out.values() if v["denizler"])
print(f"\n{covered}/{len(out)} türde deniz verisi bulundu → proxy/presence.json")
