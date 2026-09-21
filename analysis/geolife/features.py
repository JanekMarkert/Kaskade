"""Fenster-Features für die Transportmodus-Klassifikation.

Diese Datei ist die Referenz. `ios/TravelTracker/Core/Classification/
FeatureExtractor.swift` muss dieselben Werte liefern; Task 14 prüft das.
"""
from __future__ import annotations

import numpy as np
import pandas as pd

R_ERDE = 6_371_008.8
STOPP_SCHWELLE_MS = 0.5

FEATURE_NAMES = [
    "v_median", "v_p85", "v_max", "v_std",
    "a_std", "a_p85", "kurswechselrate", "stopprate", "steigrate",
]


def _abstaende(lat: np.ndarray, lon: np.ndarray) -> np.ndarray:
    dlat = np.radians(np.diff(lat))
    dlon = np.radians(np.diff(lon))
    mittel_lat = np.radians((lat[:-1] + lat[1:]) / 2.0)
    nord = dlat * R_ERDE
    ost = dlon * R_ERDE * np.cos(mittel_lat)
    return np.hypot(nord, ost)


def _kurse(lat: np.ndarray, lon: np.ndarray) -> np.ndarray:
    dlat = np.radians(np.diff(lat))
    dlon = np.radians(np.diff(lon))
    mittel_lat = np.radians((lat[:-1] + lat[1:]) / 2.0)
    return np.degrees(np.arctan2(dlon * np.cos(mittel_lat), dlat)) % 360.0


def window_features(ts: np.ndarray, lat: np.ndarray,
                    lon: np.ndarray, alt: np.ndarray) -> np.ndarray:
    dt = np.diff(ts)
    dt = np.where(dt <= 0, np.nan, dt)
    strecke = _abstaende(lat, lon)
    v = strecke / dt
    v = v[np.isfinite(v)]
    if v.size == 0:
        return np.zeros(len(FEATURE_NAMES))

    a = np.diff(v) / dt[: v.size - 1] if v.size > 1 else np.array([0.0])
    a = a[np.isfinite(a)]
    if a.size == 0:
        a = np.array([0.0])

    kurse = _kurse(lat, lon)
    if kurse.size > 1:
        dkurs = np.abs(np.diff(kurse))
        dkurs = np.minimum(dkurs, 360.0 - dkurs)
        kurswechselrate = float(np.sum(dkurs) / (ts[-1] - ts[0]))
    else:
        kurswechselrate = 0.0

    dalt = np.diff(alt)
    steigrate = float(np.sum(np.abs(dalt)) / (ts[-1] - ts[0])) if alt.size > 1 else 0.0

    return np.array([
        float(np.median(v)),
        float(np.quantile(v, 0.85)),
        float(np.max(v)),
        float(np.std(v)),
        float(np.std(a)),
        float(np.quantile(np.abs(a), 0.85)),
        kurswechselrate,
        float(np.mean(v < STOPP_SCHWELLE_MS)),
        steigrate,
    ])


def windows(df: pd.DataFrame, size: float = 60.0, overlap: float = 0.5):
    """Zerlegt eine Trajektorie in überlappende Zeitfenster."""
    schritt = size * (1.0 - overlap)
    ts = df["ts"].to_numpy()
    start = ts[0]
    while start + size <= ts[-1]:
        maske = (ts >= start) & (ts < start + size)
        if maske.sum() >= 10:
            yield df[maske], start
        start += schritt
