"""Auswertung M3: UWB gegen BLE-RSSI im Nahbereich."""
from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def error_by_distance(df: pd.DataFrame, verfahren: str) -> pd.DataFrame:
    teil = df[df["verfahren"] == verfahren]
    zeilen = []
    for (d, los), gruppe in teil.groupby(["true_distance", "los"]):
        fehler = gruppe["gemessen"].to_numpy() - d
        zeilen.append({
            "true_distance": float(d),
            "los": bool(los),
            "n": int(len(gruppe)),
            "bias_m": float(np.mean(fehler)),
            "mae_m": float(np.mean(np.abs(fehler))),
            "std_m": float(np.std(fehler)),
        })
    return pd.DataFrame(zeilen).sort_values(["los", "true_distance"])


def _plot(ax, daten: pd.DataFrame, label: str, farbe: str) -> None:
    for los, stil in [(True, "-"), (False, "--")]:
        teil = daten[daten["los"] == los]
        if teil.empty:
            continue
        ax.errorbar(teil["true_distance"], teil["mae_m"], yerr=teil["std_m"],
                    fmt=f"o{stil}", color=farbe,
                    label=f"{label} ({'LOS' if los else 'NLOS'})")


def load_sessions(directory: str | Path) -> pd.DataFrame:
    teile = [pd.read_csv(p) for p in sorted(Path(directory).glob("*.csv"))]
    if not teile:
        raise FileNotFoundError(f"keine CSV in {directory}")
    return pd.concat(teile, ignore_index=True)


def main() -> None:
    df = load_sessions("../data/measurements/m3")
    uwb = error_by_distance(df, "uwb")
    ble = error_by_distance(df, "ble")

    Path("../docs/tabellen").mkdir(parents=True, exist_ok=True)
    Path("../docs/abbildungen").mkdir(parents=True, exist_ok=True)
    pd.concat([
        uwb.assign(verfahren="uwb"), ble.assign(verfahren="ble"),
    ]).to_csv("../docs/tabellen/m3.csv", index=False)

    fig, ax = plt.subplots(figsize=(7, 5))
    _plot(ax, uwb, "UWB", "tab:blue")
    _plot(ax, ble, "BLE", "tab:orange")
    ax.set_xlabel("Solldistanz (m)")
    ax.set_ylabel("Mittlerer Absolutfehler (m)")
    ax.legend()
    fig.tight_layout()
    fig.savefig("../docs/abbildungen/m3_uwb_vs_ble.png", dpi=150)
    print("UWB MAE (LOS):", uwb[uwb["los"]]["mae_m"].mean())
    print("BLE MAE (LOS):", ble[ble["los"]]["mae_m"].mean())


if __name__ == "__main__":
    main()
