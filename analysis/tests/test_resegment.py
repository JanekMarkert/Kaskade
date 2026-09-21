import numpy as np

from evaluation import resegment


def _spur(stopp_sekunden: int, fahrt_sekunden: int):
    """Erst stehen, dann losgehen -- mit unregelmäßigen Abständen wie im Feld."""
    ts, lat, lon = [], [], []
    t = 0.0
    for i in range(stopp_sekunden):
        t += 0.97 + (i % 7) * 0.01
        ts.append(t)
        lat.append(52.5450)
        lon.append(13.3550)
    for i in range(fahrt_sekunden):
        t += 1.03 - (i % 5) * 0.01
        ts.append(t)
        lat.append(52.5450 + i * 0.000009)
        lon.append(13.3550)
    return (np.array(ts), np.array(lat), np.array(lon))


def test_trennt_stopp_und_fahrt():
    ts, lat, lon = _spur(300, 300)
    segmente = resegment.segmente(ts, lat, lon)
    assert [s["kind"] for s in segmente] == ["stop", "move"]


def test_kurze_pause_bleibt_teil_der_fahrt():
    """Unter der Mindestdauer entsteht kein eigenes Stoppsegment."""
    ts, lat, lon = _spur(40, 300)
    segmente = resegment.segmente(ts, lat, lon)
    assert [s["kind"] for s in segmente] == ["move"]


def test_gleiche_grenzen_wie_die_app():
    """Parität zu Segmenter.swift: identische Regel, identische Schnitte.

    Die Swift-Seite prüft denselben Fall in SegmenterTests.swift; weicht eine
    der beiden Seiten ab, schlägt genau einer der beiden Tests fehl.
    """
    ts, lat, lon = _spur(300, 300)
    segmente = resegment.segmente(ts, lat, lon)
    assert len(segmente) == 2
    assert segmente[0]["end_ts"] <= segmente[1]["start_ts"]
    assert segmente[0]["end_ts"] - segmente[0]["start_ts"] >= resegment.MIN_STOPP_DAUER


def test_laedt_fixes_ohne_hoehe():
    """Ältere Exporte führen kein alt-Array -- dann bleibt die Höhe 0."""
    import json
    import tempfile
    from pathlib import Path

    fc = {"type": "FeatureCollection", "features": [{
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": [[13.35, 52.54], [13.36, 52.55]]},
        "properties": {"timestamps": [2.0, 1.0], "kind": "move"},
    }]}
    with tempfile.TemporaryDirectory() as ordner:
        pfad = Path(ordner) / "trip_test.geojson"
        pfad.write_text(json.dumps(fc))
        daten = resegment.lade_fixes(pfad)
    assert list(daten["ts"]) == [1.0, 2.0]
    assert list(daten["alt"]) == [0.0, 0.0]
