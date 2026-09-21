"""GeoLife Trajectories 1.3 in ein gelabeltes DataFrame überführen."""
from __future__ import annotations

from pathlib import Path

import pandas as pd

FUSS_IN_METER = 0.3048

MODE_MAP = {
    "walk": "foot", "run": "foot",
    "bike": "bike",
    "car": "car", "taxi": "car", "bus": "car",
    "train": "train", "subway": "train", "railway": "train",
    "airplane": "plane",
}


def parse_plt(path: str | Path) -> pd.DataFrame:
    df = pd.read_csv(path, skiprows=6, header=None,
                     names=["lat", "lon", "_null", "alt_ft", "_days", "datum", "zeit"])
    zeit = pd.to_datetime(df["datum"] + " " + df["zeit"],
                          format="%Y-%m-%d %H:%M:%S", utc=True)
    return pd.DataFrame({
        "ts": zeit.astype("int64") / 1e9,
        "lat": df["lat"].astype(float),
        "lon": df["lon"].astype(float),
        "alt_m": df["alt_ft"].astype(float) * FUSS_IN_METER,
    })


def parse_labels(path: str | Path) -> pd.DataFrame:
    df = pd.read_csv(path, sep="\t")
    return pd.DataFrame({
        "start_ts": pd.to_datetime(df["Start Time"], format="%Y/%m/%d %H:%M:%S",
                                   utc=True).astype("int64") / 1e9,
        "end_ts": pd.to_datetime(df["End Time"], format="%Y/%m/%d %H:%M:%S",
                                 utc=True).astype("int64") / 1e9,
        "mode": df["Transportation Mode"].str.strip(),
    })


def build_dataset(root: str | Path) -> pd.DataFrame:
    teile = []
    for nutzer in sorted(Path(root).iterdir()):
        labels_datei = nutzer / "labels.txt"
        if not labels_datei.exists():
            continue
        labels = parse_labels(labels_datei)
        labels = labels[labels["mode"].isin(MODE_MAP)]
        if labels.empty:
            continue
        for plt in sorted((nutzer / "Trajectory").glob("*.plt")):
            punkte = parse_plt(plt)
            for _, l in labels.iterrows():
                treffer = punkte[(punkte["ts"] >= l["start_ts"])
                                 & (punkte["ts"] <= l["end_ts"])].copy()
                if len(treffer) < 60:
                    continue
                treffer["mode"] = MODE_MAP[l["mode"]]
                treffer["user"] = nutzer.name
                teile.append(treffer)
    if not teile:
        raise ValueError(f"keine gelabelten Trajektorien unter {root}")
    return pd.concat(teile, ignore_index=True)
