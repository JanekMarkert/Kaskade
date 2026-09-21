"""Auswertung M2: eigenes Modell gegen CMMotionActivity."""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import confusion_matrix, f1_score

from evaluation import resegment

KLASSEN = ["foot", "bike", "car", "train", "plane"]
# plane kommt im Feld nicht vor und wäre ein Null-F1 für beide Verfahren; der
# Macro-Durchschnitt läuft deshalb über die vier Klassen, die gefahren wurden
# (wie macro_f1_ohne_plane beim Training).
FELDKLASSEN = ["foot", "bike", "car", "train"]

CM_MAP = {
    "walking": "foot",
    "running": "foot",
    "cycling": "bike",
    "automotive": "car",
    "stationary": None,
    "unknown": None,
}


def map_cm_activity(cm: str) -> str | None:
    return CM_MAP.get(cm)


def confusion(y_true, y_pred, labels) -> np.ndarray:
    return confusion_matrix(y_true, y_pred, labels=labels)


def load_track(path: str | Path) -> pd.DataFrame:
    fc = json.loads(Path(path).read_text())
    zeilen = [
        {
            "segment_id": f["properties"]["segment_id"],
            "start_ts": f["properties"]["start_ts"],
            "end_ts": f["properties"]["end_ts"],
            "kind": f["properties"]["kind"],
            "y_true": f["properties"]["label_mode"],
            "y_model": f["properties"]["predicted_mode"],
        }
        for f in fc["features"]
    ]
    df = pd.DataFrame(zeilen)
    return df[(df["kind"] == "move") & df["y_true"].notna()]


def compare(track: pd.DataFrame, activities: pd.DataFrame) -> pd.DataFrame:
    """Ergänzt je Segment die häufigste CMMotionActivity als Baseline."""
    baseline = []
    for _, s in track.iterrows():
        im_segment = activities[(activities["ts"] >= s["start_ts"])
                                & (activities["ts"] <= s["end_ts"])]
        gemappt = im_segment["cm_activity"].map(map_cm_activity).dropna()
        baseline.append(gemappt.mode().iloc[0] if not gemappt.empty else None)
    out = track.copy()
    out["y_baseline"] = baseline
    return out


def load_all_tracks(directory: str | Path) -> pd.DataFrame:
    """Liest jeden trip_*.geojson-Export mit passender _activity.csv ein."""
    teile = []
    for geojson_pfad in sorted(Path(directory).glob("trip_*.geojson")):
        aktivitaet_pfad = geojson_pfad.with_name(geojson_pfad.stem + "_activity.csv")
        if not aktivitaet_pfad.exists():
            continue
        track = load_track(geojson_pfad)
        activities = pd.read_csv(aktivitaet_pfad)
        teile.append(compare(track, activities))
    if not teile:
        raise FileNotFoundError(f"keine trip_*.geojson mit _activity.csv in {directory}")
    return pd.concat(teile, ignore_index=True)


def handlabel(labels: pd.DataFrame, trip: str, start_ts: float, end_ts: float) -> str | None:
    """Handlabel des Abschnitts, in dem die Mitte des Segments liegt."""
    mitte = (start_ts + end_ts) / 2
    treffer = labels[(labels["trip"] == trip)
                     & (labels["start_ts"] <= mitte) & (labels["end_ts"] >= mitte)]
    return None if treffer.empty else str(treffer.iloc[0]["label"])


def _gespeicherte_vorhersagen(pfad: Path) -> list[dict]:
    """Vorhersagen, die die App zur Aufzeichnungszeit in den Export geschrieben hat."""
    fc = json.loads(Path(pfad).read_text())
    return [
        {"start_ts": f["properties"]["start_ts"], "end_ts": f["properties"]["end_ts"],
         "mode": f["properties"]["predicted_mode"], "konfidenz": f["properties"]["confidence"]}
        for f in fc["features"]
        if f["properties"]["kind"] == "move" and f["properties"].get("predicted_mode")
    ]


def offline_vergleich(verzeichnis: str | Path) -> pd.DataFrame:
    """Segmentiert und klassifiziert jeden Export neu, statt den in der App
    gespeicherten Werten zu vertrauen.

    Die Aufzeichnungen vom 18. und 20.09. entstanden mit einer Fassung, in der
    die Stopperkennung nie ansprach (siehe Segmenter.swift) -- ihre gespeicherte
    Segmentierung ist damit unbrauchbar. Regel, Features und Modell sind
    dieselben wie in der App, abgesichert über test_resegment.py und
    FeatureParityTests.swift.
    """
    verzeichnis = Path(verzeichnis)
    labels = pd.read_csv(verzeichnis / "handlabels.csv")
    modell = resegment._modell()

    zeilen = []
    for pfad in sorted(verzeichnis.glob("trip_*.geojson")):
        trip = pfad.stem
        aktivitaet_pfad = pfad.with_name(f"{trip}_activity.csv")
        if not aktivitaet_pfad.exists():
            continue
        activities = pd.read_csv(aktivitaet_pfad)
        d = resegment.lade_fixes(pfad)
        gespeichert = _gespeicherte_vorhersagen(pfad)

        for s in resegment.segmente(d["ts"], d["lat"], d["lon"]):
            if s["kind"] != "move":
                continue
            y_true = handlabel(labels, trip, s["start_ts"], s["end_ts"])
            if y_true is None:
                continue
            a, b = s["start_i"], s["end_i"] + 1
            # Deckt sich das Segment mit dem gespeicherten, gilt die Vorhersage
            # des Geräts: sie entstand mit echter Höhe. Neu gerechnet wird nur,
            # wo die gespeicherte Segmentierung nicht stimmt.
            treffer = next((g for g in gespeichert
                            if abs(g["start_ts"] - s["start_ts"]) < 1.0
                            and abs(g["end_ts"] - s["end_ts"]) < 1.0), None)
            if treffer is not None:
                vorhersage, quelle = (treffer["mode"], treffer["konfidenz"]), "app"
            else:
                vorhersage = resegment.klassifiziere(d["ts"][a:b], d["lat"][a:b],
                                                     d["lon"][a:b], d["alt"][a:b], modell)
                quelle = "offline"
            im_segment = activities[(activities["ts"] >= s["start_ts"])
                                    & (activities["ts"] <= s["end_ts"])]
            gemappt = im_segment["cm_activity"].map(map_cm_activity).dropna()
            zeilen.append({
                "trip": trip,
                "start_ts": s["start_ts"],
                "dauer_min": (s["end_ts"] - s["start_ts"]) / 60,
                "y_true": y_true,
                "y_model": vorhersage[0] if vorhersage else None,
                "konfidenz": vorhersage[1] if vorhersage else None,
                "quelle": quelle,
                "y_baseline": gemappt.mode().iloc[0] if not gemappt.empty else None,
            })
    return pd.DataFrame(zeilen)


def main() -> None:
    df = offline_vergleich("../data/tracks")

    zeilen = []
    for spalte, name in [("y_model", "eigenes Modell"), ("y_baseline", "CMMotionActivity")]:
        gueltig = df[df[spalte].notna()]
        zeilen.append({
            "verfahren": name,
            "n_segmente": len(df),
            "n_klassifiziert": len(gueltig),
            "macro_f1": f1_score(gueltig["y_true"], gueltig[spalte],
                                 labels=FELDKLASSEN, average="macro", zero_division=0),
            "treffer": float((gueltig["y_true"] == gueltig[spalte]).mean()),
        })
    Path("../docs/tabellen").mkdir(parents=True, exist_ok=True)
    Path("../docs/abbildungen").mkdir(parents=True, exist_ok=True)
    pd.DataFrame(zeilen).to_csv("../docs/tabellen/m2_vergleich.csv", index=False)
    df.to_csv("../docs/tabellen/m2_segmente.csv", index=False)
    je_klasse = pd.DataFrame({
        "klasse": FELDKLASSEN,
        "n_segmente": [int((df["y_true"] == k).sum()) for k in FELDKLASSEN],
        **{name: f1_score(df["y_true"], df[spalte], labels=FELDKLASSEN,
                          average=None, zero_division=0)
           for spalte, name in [("y_model", "f1_modell"), ("y_baseline", "f1_baseline")]},
    })
    je_klasse.to_csv("../docs/tabellen/m2_je_klasse.csv", index=False)

    m = confusion(df["y_true"], df["y_model"], KLASSEN)
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.imshow(m, cmap="Blues")
    ax.set_xticks(range(len(KLASSEN)), KLASSEN)
    ax.set_yticks(range(len(KLASSEN)), KLASSEN)
    ax.set_xlabel("vorhergesagt")
    ax.set_ylabel("tatsächlich (Handlabel)")
    for i in range(len(KLASSEN)):
        for j in range(len(KLASSEN)):
            ax.text(j, i, str(m[i, j]), ha="center", va="center")
    fig.tight_layout()
    fig.savefig("../docs/abbildungen/m2_konfusion.png", dpi=150)
    print(df[["trip", "dauer_min", "y_true", "y_model", "konfidenz", "quelle", "y_baseline"]]
          .to_string(index=False))
    print()
    print(pd.DataFrame(zeilen))
    print()
    print(je_klasse.round(2).to_string(index=False))


if __name__ == "__main__":
    main()
