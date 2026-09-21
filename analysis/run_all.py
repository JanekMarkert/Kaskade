"""Ein Befehl, das alle Abbildungen und Tabellen aus den mitgelieferten
Messdaten neu erzeugt. Aufruf von der Repo-Wurzel: python analysis/run_all.py
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
os.chdir(Path(__file__).resolve().parent)  # M1-M4-Skripte nutzen "../data/..." relativ zu analysis/

from evaluation import cascade, m1_gnss, m2_classifier, m3_proximity, m4_lidar  # noqa: E402


def main() -> None:
    for name, fn in [
        ("M1 GNSS", m1_gnss.main),
        ("M3 UWB/BLE", m3_proximity.main),
        ("M4 LiDAR", m4_lidar.main),
        ("Ortungskaskade", cascade.main),
    ]:
        print(f"\n=== {name} ===")
        fn()

    print("\n=== M2 Transportmodus ===")
    try:
        m2_classifier.main()
    except FileNotFoundError as e:
        print(f"übersprungen, noch kein Feldtest-Track vorhanden: {e}")


if __name__ == "__main__":
    main()
