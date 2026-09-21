import json
from pathlib import Path

import numpy as np
from geolife.features import FEATURE_NAMES, window_features

def test_feature_namen_sind_stabil_und_eindeutig():
    assert len(FEATURE_NAMES) == len(set(FEATURE_NAMES))
    assert FEATURE_NAMES[0] == "v_median"
    assert FEATURE_NAMES == [
        "v_median", "v_p85", "v_max", "v_std",
        "a_std", "a_p85", "kurswechselrate", "stopprate", "steigrate",
    ]

def test_gleichfoermige_bewegung_gibt_erwartete_geschwindigkeit():
    # 1 Hz, je Schritt 0.000009 Grad Breite ~ 1.0 m/s
    ts = np.arange(60, dtype=float)
    lat = 52.5450 + ts * 0.000009
    lon = np.full(60, 13.3550)
    alt = np.zeros(60)
    f = window_features(ts, lat, lon, alt)
    v_median = f[FEATURE_NAMES.index("v_median")]
    assert 0.9 < v_median < 1.1
    assert f[FEATURE_NAMES.index("stopprate")] == 0.0

def test_stillstand_gibt_stopprate_eins():
    ts = np.arange(60, dtype=float)
    lat = np.full(60, 52.5450)
    lon = np.full(60, 13.3550)
    alt = np.zeros(60)
    f = window_features(ts, lat, lon, alt)
    assert f[FEATURE_NAMES.index("stopprate")] == 1.0

def test_fixture_stimmt_mit_aktueller_implementierung_ueberein():
    """Schützt vor stillen Änderungen an der Feature-Berechnung."""
    fixture = json.loads(
        Path("geolife/fixtures/window_reference.json").read_text())
    f = window_features(
        np.array(fixture["ts"]), np.array(fixture["lat"]),
        np.array(fixture["lon"]), np.array(fixture["alt"]))
    erwartet = np.array(fixture["features"])
    assert np.allclose(f, erwartet, atol=1e-6)
