"""Sucht die nächste ALKIS-Gebäudeecke zu einer WGS84-Koordinate über den
offenen Berliner WFS-Dienst (gdi.berlin.de) — spart den manuellen Weg über
den FIS-Broker-Kartenviewer für die Referenzpunkte in HERKUNFT.md.

Datenquelle: Land Berlin, Amtliches Liegenschaftskataster-Informationssystem
(ALKIS), Datenlizenz Deutschland – Namensnennung 2.0. Ersetzt nicht die
Vor-Ort-Verifikation und das Foto der Markierung.

Verwendung: python fetch_alkis_corner.py <lat> <lon> [radius_m]
"""
import json
import math
import sys
import urllib.request

from pyproj import Transformer

WFS_URL = "https://gdi.berlin.de/services/wfs/alkis_gebaeude"
_zu_utm = Transformer.from_crs("EPSG:4326", "EPSG:25833", always_xy=True)
_zu_wgs84 = Transformer.from_crs("EPSG:25833", "EPSG:4326", always_xy=True)


def naechste_ecke(lat: float, lon: float, radius_m: float = 150.0) -> dict:
    x, y = _zu_utm.transform(lon, lat)
    bbox = f"{x - radius_m},{y - radius_m},{x + radius_m},{y + radius_m},EPSG:25833"
    url = (f"{WFS_URL}?service=WFS&version=2.0.0&request=GetFeature"
           f"&typeNames=alkis_gebaeude:gebaeude&outputFormat=application/json"
           f"&bbox={bbox}")
    with urllib.request.urlopen(url, timeout=30) as resp:
        daten = json.load(resp)

    beste = None
    for feature in daten.get("features", []):
        geom = feature["geometry"]
        ringe = (geom["coordinates"][0] if geom["type"] == "Polygon"
                 else geom["coordinates"][0][0])
        for ex, ey in ringe:
            abstand = math.hypot(ex - x, ey - y)
            if beste is None or abstand < beste[0]:
                beste = (abstand, ex, ey, feature["id"])

    if beste is None:
        raise RuntimeError(f"keine ALKIS-Gebäude im Umkreis von {radius_m} m gefunden")

    abstand, ex, ey, feature_id = beste
    elon, elat = _zu_wgs84.transform(ex, ey)
    return {
        "feature_id": feature_id,
        "utm33": (round(ex, 3), round(ey, 3)),
        "wgs84": (round(elat, 7), round(elon, 7)),
        "abstand_m": round(abstand, 1),
    }


if __name__ == "__main__":
    lat, lon = float(sys.argv[1]), float(sys.argv[2])
    radius = float(sys.argv[3]) if len(sys.argv) > 3 else 150.0
    ergebnis = naechste_ecke(lat, lon, radius)
    print(json.dumps(ergebnis, indent=2, ensure_ascii=False))
