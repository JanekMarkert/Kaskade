"""Auswertung M4: LiDAR-Tiefe gegen Maßband."""
from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

LOW_CONFIDENCE = 0  # ARConfidenceLevel.low


def error_by_distance(df: pd.DataFrame) -> pd.DataFrame:
    gueltig = df[df["confidence"] > LOW_CONFIDENCE]
    zeilen = []
    for (d, licht), gruppe in gueltig.groupby(["true_distance", "lighting"]):
        fehler = gruppe["depth_m"].to_numpy() - d
        zeilen.append({
            "true_distance": float(d),
            "lighting": str(licht),
            "n": int(len(gruppe)),
            "bias_m": float(np.mean(fehler)),
            "mae_m": float(np.mean(np.abs(fehler))),
            "std_m": float(np.std(fehler)),
        })
    return pd.DataFrame(zeilen).sort_values(["lighting", "true_distance"])


def load_sessions(directory: str | Path) -> pd.DataFrame:
    teile = [pd.read_csv(p) for p in sorted(Path(directory).glob("*.csv"))]
    if not teile:
        raise FileNotFoundError(f"keine CSV in {directory}")
    return pd.concat(teile, ignore_index=True)


def main() -> None:
    df = load_sessions("../data/measurements/m4")
    tabelle = error_by_distance(df)
    Path("../docs/tabellen").mkdir(parents=True, exist_ok=True)
    Path("../docs/abbildungen").mkdir(parents=True, exist_ok=True)
    tabelle.to_csv("../docs/tabellen/m4.csv", index=False)

    fig, ax = plt.subplots(figsize=(7, 5))
    for licht, stil in [("tag", "-"), ("nacht", "--")]:
        teil = tabelle[tabelle["lighting"] == licht]
        if teil.empty:
            continue
        ax.errorbar(teil["true_distance"], teil["mae_m"], yerr=teil["std_m"],
                    fmt=f"o{stil}", label=licht)
    ax.set_xlabel("Solldistanz (m)")
    ax.set_ylabel("Mittlerer Absolutfehler (m)")
    ax.legend()
    fig.tight_layout()
    fig.savefig("../docs/abbildungen/m4_lidar.png", dpi=150)
    print(tabelle)


if __name__ == "__main__":
    main()
