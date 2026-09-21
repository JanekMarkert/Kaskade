"""Segmentierung und Klassifikation außerhalb der App.

Spiegelt Segmenter.swift und ModeClassifier.swift: dieselbe Stoppregel
(gleitendes Fenster über minStopDuration, Radius unter maxStopRadius),
dieselben neun Features aus geolife/features.py, dasselbe Core-ML-Modell.
Damit lässt sich M2 aus den GeoJSON-Exporten nachrechnen, statt sich auf die
Werte zu verlassen, die das Gerät zur Aufzeichnungszeit hineingeschrieben hat.
"""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np

from geolife.features import window_features

MIN_STOPP_DAUER = 180.0
MAX_STOPP_RADIUS = 50.0
MODELL_PFAD = Path(__file__).resolve().parents[1] / "geolife" / "out" / "TransportMode.mlmodel"

FEATURE_EINGABEN = [
    "v_median", "v_p85", "v_max", "v_std", "a_std", "a_p85",
    "kurswechselrate", "stopprate", "steigrate",
]


def _radius(lat: np.ndarray, lon: np.ndarray) -> float:
    """Größter Abstand zum Mittelpunkt, in Metern."""
    mlat, mlon = float(np.mean(lat)), float(np.mean(lon))
    dlat = np.radians(lat - mlat)
    dlon = np.radians(lon - mlon) * np.cos(np.radians(mlat))
    return float(np.max(np.hypot(dlat, dlon) * 6_371_000.0))


def segmente(ts: np.ndarray, lat: np.ndarray, lon: np.ndarray,
             min_stopp_dauer: float = MIN_STOPP_DAUER,
             max_stopp_radius: float = MAX_STOPP_RADIUS) -> list[dict]:
    """Zerlegt eine Spur in abwechselnde stop- und move-Abschnitte."""
    n = len(ts)
    if n < 2:
        return []

    ist_stopp = np.zeros(n, dtype=bool)
    start = 0
    for ende in range(n):
        # Das Fenster darf schrumpfen, solange es die Mindestdauer noch abdeckt.
        while start < ende and ts[ende] - ts[start + 1] >= min_stopp_dauer:
            start += 1
        if ts[ende] - ts[start] < min_stopp_dauer:
            continue
        if _radius(lat[start:ende + 1], lon[start:ende + 1]) <= max_stopp_radius:
            ist_stopp[start:ende + 1] = True

    ergebnis = []
    lauf = 0
    for i in range(1, n + 1):
        if i < n and ist_stopp[i] == ist_stopp[lauf]:
            continue
        ergebnis.append({
            "start_i": lauf, "end_i": i - 1,
            "start_ts": float(ts[lauf]), "end_ts": float(ts[i - 1]),
            "kind": "stop" if ist_stopp[lauf] else "move",
        })
        lauf = i
    return ergebnis


def _modell():
    import coremltools as ct
    return ct.models.MLModel(str(MODELL_PFAD))


def klassifiziere(ts: np.ndarray, lat: np.ndarray, lon: np.ndarray,
                  alt: np.ndarray, modell=None) -> tuple[str, float] | None:
    """Ein Modus je Abschnitt, wie ModeClassifier.classify in der App."""
    if len(ts) < 10:
        return None
    werte = window_features(ts, lat, lon, alt)
    modell = modell if modell is not None else _modell()
    ausgabe = modell.predict(dict(zip(FEATURE_EINGABEN, map(float, werte))))
    klasse = ausgabe["mode"]
    # Der coremltools-Export liefert rohe Baumstimmen, keine Wahrscheinlichkeiten.
    summe = sum(ausgabe["classProbability"].values())
    return klasse, (ausgabe["classProbability"][klasse] / summe if summe else 0.0)


def lade_fixes(pfad: str | Path) -> dict[str, np.ndarray]:
    """Alle Fixes eines Exports, über die Segmentgrenzen hinweg und nach Zeit sortiert."""
    fc = json.loads(Path(pfad).read_text())
    ts, lat, lon, alt = [], [], [], []
    for f in fc["features"]:
        p = f["properties"]
        zeiten = p["timestamps"]
        zeiten = json.loads(zeiten) if isinstance(zeiten, str) else zeiten
        hoehen = p.get("alt")
        hoehen = json.loads(hoehen) if isinstance(hoehen, str) else hoehen
        koordinaten = f["geometry"]["coordinates"]
        ts.extend(zeiten)
        lat.extend(k[1] for k in koordinaten)
        lon.extend(k[0] for k in koordinaten)
        # Ältere Exporte führen keine Höhe; dann bleibt die Steigrate 0.
        alt.extend(hoehen if hoehen else [0.0] * len(koordinaten))

    reihe = np.argsort(np.asarray(ts, dtype=float))
    return {
        "ts": np.asarray(ts, dtype=float)[reihe],
        "lat": np.asarray(lat, dtype=float)[reihe],
        "lon": np.asarray(lon, dtype=float)[reihe],
        "alt": np.asarray(alt, dtype=float)[reihe],
    }
