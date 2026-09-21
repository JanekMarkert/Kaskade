"""Training des Transportmodus-Klassifikators und Export nach Core ML."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix

from .features import windows, window_features

KLASSEN = ["foot", "bike", "car", "train", "plane"]


def build_matrix(df: pd.DataFrame):
    zeilen, labels, gruppen = [], [], []
    for (user, mode), teil in df.groupby(["user", "mode"], sort=False):
        teil = teil.sort_values("ts")
        for fenster, _ in windows(teil):
            zeilen.append(window_features(
                fenster["ts"].to_numpy(), fenster["lat"].to_numpy(),
                fenster["lon"].to_numpy(), fenster["alt_m"].to_numpy()))
            labels.append(mode)
            gruppen.append(user)
    return np.vstack(zeilen), np.array(labels), np.array(gruppen)


def subsample_by_user(df: pd.DataFrame, n_users: int, seed: int = 0,
                      top_je_klasse: int = 2) -> pd.DataFrame:
    """Reduziert den Datensatz auf n_users Nutzer. Behält je Modus die
    top_je_klasse Nutzer mit den meisten Fixes in diesem Modus, damit seltene
    Klassen (v.a. bike, plane) nicht durch zufällige Auswahl verschwinden —
    bike etwa steckt zu 72% in nur drei Nutzern."""
    pflicht: set[str] = set()
    for modus in df["mode"].unique():
        top = (df.loc[df["mode"] == modus, "user"]
                 .value_counts().head(top_je_klasse).index)
        pflicht.update(top)
    rest = [u for u in df["user"].unique() if u not in pflicht]
    rng = np.random.default_rng(seed)
    n_rest = max(0, n_users - len(pflicht))
    gewaehlt = pflicht | set(
        rng.choice(rest, size=min(n_rest, len(rest)), replace=False))
    return df[df["user"].isin(gewaehlt)]


def split_by_user(groups: np.ndarray, test_anteil: float = 0.3, seed: int = 0):
    nutzer = np.unique(groups)
    rng = np.random.default_rng(seed)
    rng.shuffle(nutzer)
    n_test = max(1, int(round(len(nutzer) * test_anteil)))
    test_nutzer = set(nutzer[:n_test])
    ist_test = np.array([g in test_nutzer for g in groups])
    return np.where(~ist_test)[0], np.where(ist_test)[0]


def train(X, y, groups, seed: int = 0):
    """RandomForestClassifier statt GradientBoostingClassifier: laut Plan als
    Fallback vorgesehen (auch für den Core-ML-Export), trainiert aber vor
    allem parallel über n_jobs=-1 statt einzelthreadig — GradientBoosting
    brauchte auf diesem Datensatz über 44 Minuten pro Lauf.

    class_weight="balanced" wurde getestet und verworfen (macro-F1 minimal
    schlechter als ohne).

    max_depth=None (volle Bäume) erreicht zwar dieselbe Genauigkeit wie
    max_depth=12, exportiert als Core-ML-Modell aber über 800 MB — für eine
    iOS-App unbrauchbar. max_depth=12 liefert praktisch identisches
    macro_f1_ohne_plane (0.704 vs. 0.703) bei 16x weniger Knoten im Wald
    (757.892 vs. 12.169.444 bei 150 Bäumen). n_estimators=150 statt 300
    halbiert die Modellgröße nochmal, ohne messbaren Genauigkeitsverlust.

    "plane" bleibt trotzdem schwach: von 56 GeoLife-Nutzern haben nur 4
    überhaupt Flugdaten (rund 9000 von 5.45 Mio. Fixes). Das ist eine
    Grenze des Datensatzes, keine Trainingsschwäche — deshalb wird
    macro_f1_ohne_plane zusätzlich ausgewiesen."""
    train_idx, test_idx = split_by_user(groups, seed=seed)
    modell = RandomForestClassifier(
        n_estimators=150, max_depth=12, n_jobs=-1, random_state=seed)
    modell.fit(X[train_idx], y[train_idx])
    y_pred = modell.predict(X[test_idx])
    report = classification_report(
        y[test_idx], y_pred, output_dict=True, zero_division=0)
    f1_ohne_plane = np.mean([report[k]["f1-score"] for k in KLASSEN
                             if k != "plane" and k in report])
    bericht = {
        "report": report,
        "macro_f1_ohne_plane": float(f1_ohne_plane),
        "confusion": confusion_matrix(
            y[test_idx], y_pred, labels=KLASSEN).tolist(),
        "labels": KLASSEN,
        "n_train": int(len(train_idx)),
        "n_test": int(len(test_idx)),
        "modell": "RandomForestClassifier(n_estimators=150, max_depth=12)",
    }
    return modell, bericht


def export_coreml(modell, pfad: str | Path) -> None:
    import coremltools as ct

    from .features import FEATURE_NAMES
    mlmodel = ct.converters.sklearn.convert(
        modell, input_features=FEATURE_NAMES, output_feature_names="mode")
    mlmodel.short_description = "Transportmodus aus GNSS-Fensterfeatures"
    mlmodel.save(str(pfad))


def build_matrix_cached(df: pd.DataFrame, cache_pfad: str | Path):
    """Wie build_matrix, aber auf Platte zwischengespeichert. build_matrix ist
    eine reine Python-Schleife über alle Zeitfenster und dominiert die
    Laufzeit (bei 3.3 Mio. Fixes rund 45 Minuten) — der Cache macht spätere
    Hyperparameter-Experimente sekundenschnell statt wieder 45+ Minuten."""
    cache_pfad = Path(cache_pfad)
    if cache_pfad.exists():
        daten = np.load(cache_pfad, allow_pickle=True)
        return daten["X"], daten["y"], daten["groups"]
    X, y, groups = build_matrix(df)
    cache_pfad.parent.mkdir(parents=True, exist_ok=True)
    np.savez(cache_pfad, X=X, y=y, groups=groups)
    return X, y, groups


def main(n_users: int | None = None) -> None:
    """n_users=None trainiert auf dem vollen GeoLife-Datensatz (56 Nutzer,
    5.45 Mio. Fixes) — nötig, weil bike/car sich bei kleineren Stichproben
    kaum trennen ließen (macro-F1 0.38 bei 20 Nutzern, 0.57 auf dem vollen
    Datensatz). subsample_by_user bleibt für schnelle Entwicklungsläufe
    nutzbar (n_users=20 o.ä.), ist aber nicht mehr der Standard."""
    df = pd.read_parquet("geolife/dataset.parquet")
    cache_pfad = "geolife/out/matrix_cache_full.npz"
    if n_users is not None:
        df = subsample_by_user(df, n_users=n_users)
        print(f"Stichprobe: {df['user'].nunique()} Nutzer, {len(df)} Fixes")
        cache_pfad = f"geolife/out/matrix_cache_{n_users}.npz"
    X, y, groups = build_matrix_cached(df, cache_pfad)
    modell, bericht = train(X, y, groups)
    Path("geolife/out").mkdir(parents=True, exist_ok=True)
    Path("geolife/out/metrics.json").write_text(json.dumps(bericht, indent=2))
    export_coreml(modell, "geolife/out/TransportMode.mlmodel")
    print("Macro-F1:", bericht["report"]["macro avg"]["f1-score"])
    print("Macro-F1 ohne plane:", bericht["macro_f1_ohne_plane"])


if __name__ == "__main__":
    main()
