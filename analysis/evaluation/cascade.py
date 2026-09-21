"""Ortungskaskade: Fehler über Reichweite, alle vier Verfahren in einer Abbildung."""
from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def gewichteter_gnss_fehler(m1: pd.DataFrame) -> float:
    """CEP95 über alle Referenzpunkte, gewichtet nach Fixanzahl je Punkt."""
    return float((m1["cep95_m"] * m1["n"]).sum() / m1["n"].sum())


def main() -> None:
    m1 = pd.read_csv("../docs/tabellen/m1.csv")
    m3 = pd.read_csv("../docs/tabellen/m3.csv")
    m4 = pd.read_csv("../docs/tabellen/m4.csv")

    fig, ax = plt.subplots(figsize=(8, 6))

    gnss_fehler = gewichteter_gnss_fehler(m1)
    ax.axhline(gnss_fehler, linestyle=":", color="tab:green",
               label=f"GNSS (global, CEP95≈{gnss_fehler:.1f} m)")

    for verfahren, farbe in [("uwb", "tab:blue"), ("ble", "tab:orange")]:
        teil = m3[(m3["verfahren"] == verfahren) & (m3["los"])].sort_values("true_distance")
        ax.plot(teil["true_distance"], teil["mae_m"], "o-", color=farbe,
                 label=f"{verfahren.upper()} (LOS)")

    lidar = m4.groupby("true_distance")["mae_m"].mean().reset_index().sort_values("true_distance")
    ax.plot(lidar["true_distance"], lidar["mae_m"], "o-", color="tab:red", label="LiDAR")

    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("Distanz (m, log)")
    ax.set_ylabel("Fehler (m, log)")
    ax.set_title("Ortungskaskade: vier Verfahren, ein Protokoll")
    ax.legend()
    fig.tight_layout()

    Path("../docs/abbildungen").mkdir(parents=True, exist_ok=True)
    fig.savefig("../docs/abbildungen/cascade.png", dpi=150)
    print(f"GNSS CEP95 (gewichtet über {len(m1)} Punkte): {gnss_fehler:.2f} m")


if __name__ == "__main__":
    main()
