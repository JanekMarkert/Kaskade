"""Auswertung M1: gemeldete gegen tatsächliche GNSS-Genauigkeit."""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

R_ERDE = 6_371_008.8  # mittlerer Erdradius in Metern


def error_series(df: pd.DataFrame, ref: dict) -> np.ndarray:
    """Horizontaler Abstand jedes Fixes zum Referenzpunkt in Metern."""
    dlat = np.radians(df["lat"].to_numpy() - ref["lat"])
    dlon = np.radians(df["lon"].to_numpy() - ref["lon"])
    mittel_lat = np.radians((df["lat"].to_numpy() + ref["lat"]) / 2.0)
    nord = dlat * R_ERDE
    ost = dlon * R_ERDE * np.cos(mittel_lat)
    return np.hypot(nord, ost)


def cep(errors: np.ndarray, q: float) -> float:
    """Circular Error Probable: das q-Quantil der Fehlerbeträge."""
    return float(np.quantile(np.asarray(errors, dtype=float), q))


def load_sessions(directory: str | Path) -> pd.DataFrame:
    teile = [pd.read_csv(p) for p in sorted(Path(directory).glob("*.csv"))]
    if not teile:
        raise FileNotFoundError(f"keine CSV in {directory}")
    return pd.concat(teile, ignore_index=True)


def load_reference(path: str | Path) -> dict[str, dict]:
    fc = json.loads(Path(path).read_text())
    return {
        f["properties"]["id"]: {
            "lat": f["geometry"]["coordinates"][1],
            "lon": f["geometry"]["coordinates"][0],
            "environment": f["properties"]["environment"],
        }
        for f in fc["features"]
    }


def calibration_table(df: pd.DataFrame, refs: dict[str, dict]) -> pd.DataFrame:
    zeilen = []
    for pid, gruppe in df.groupby("point_id"):
        fehler = error_series(gruppe, refs[pid])
        gemeldet = gruppe["h_acc"].to_numpy()
        zeilen.append({
            "point_id": pid,
            "environment": refs[pid]["environment"],
            "n": len(gruppe),
            "cep50_m": cep(fehler, 0.50),
            "cep95_m": cep(fehler, 0.95),
            "gemeldet_median_m": float(np.median(gemeldet)),
            "faktor_cep95_zu_gemeldet": cep(fehler, 0.95) / float(np.median(gemeldet)),
        })
    return pd.DataFrame(zeilen)


def main() -> None:
    df = load_sessions("../data/measurements/m1_static")
    refs = load_reference("../data/reference/reference_points.geojson")
    tabelle = calibration_table(df, refs)

    Path("../docs/tabellen").mkdir(parents=True, exist_ok=True)
    Path("../docs/abbildungen").mkdir(parents=True, exist_ok=True)
    tabelle.to_csv("../docs/tabellen/m1.csv", index=False)

    fig, achsen = plt.subplots(1, len(refs), figsize=(5 * len(refs), 5))
    if len(refs) == 1:
        achsen = [achsen]
    for ax, (pid, gruppe) in zip(achsen, df.groupby("point_id")):
        ref = refs[pid]
        dlat = (gruppe["lat"] - ref["lat"]) * 111_320
        dlon = (gruppe["lon"] - ref["lon"]) * 111_320 * np.cos(np.radians(ref["lat"]))
        ax.scatter(dlon, dlat, s=8, alpha=0.5)
        fehler = error_series(gruppe, ref)
        for q, stil in [(0.50, "-"), (0.95, "--")]:
            r = cep(fehler, q)
            kreis = plt.Circle((0, 0), r, fill=False, linestyle=stil, color="tab:red")
            ax.add_patch(kreis)
        ax.set_title(f"{pid} ({ref['environment']})")
        ax.set_xlabel("Ost (m)")
        ax.set_ylabel("Nord (m)")
        ax.set_aspect("equal")
    fig.tight_layout()
    fig.savefig("../docs/abbildungen/m1_streuung.png", dpi=150)

    fig2, ax2 = plt.subplots(figsize=(6, 6))
    ax2.scatter(tabelle["gemeldet_median_m"], tabelle["cep95_m"])
    grenze = max(tabelle["gemeldet_median_m"].max(), tabelle["cep95_m"].max()) * 1.1
    ax2.plot([0, grenze], [0, grenze], linestyle="--", color="gray")
    ax2.set_xlabel("gemeldete Genauigkeit, Median (m)")
    ax2.set_ylabel("tatsächlicher Fehler, CEP95 (m)")
    fig2.tight_layout()
    fig2.savefig("../docs/abbildungen/m1_kalibrierung.png", dpi=150)

    print(tabelle)


if __name__ == "__main__":
    main()
