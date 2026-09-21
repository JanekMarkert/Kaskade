import numpy as np
import pandas as pd
from geolife.train import build_matrix, split_by_user, subsample_by_user, train


def test_split_trennt_nach_nutzer_nicht_nach_fenster():
    groups = np.array(["u1"] * 50 + ["u2"] * 50 + ["u3"] * 50)
    train_idx, test_idx = split_by_user(groups, test_anteil=0.34, seed=1)
    train_users = set(groups[train_idx])
    test_users = set(groups[test_idx])
    assert train_users.isdisjoint(test_users)
    assert len(test_users) >= 1


def test_build_matrix_liefert_eine_zeile_je_fenster():
    ts = np.arange(0, 181, 1.0)  # 180s Spanne, damit windows() 5 Fenster liefert
    df = pd.DataFrame({
        "ts": ts,
        "lat": 52.545 + ts * 9e-6,
        "lon": np.full(len(ts), 13.355),
        "alt_m": np.zeros(len(ts)),
        "mode": ["foot"] * len(ts),
        "user": ["u1"] * len(ts),
    })
    X, y, groups = build_matrix(df)
    assert X.shape == (5, 9)
    assert set(y) == {"foot"}
    assert set(groups) == {"u1"}


def test_train_dokumentiert_modell_und_f1_ohne_plane():
    rng = np.random.default_rng(0)
    nutzer = np.array([f"u{i}" for i in range(6) for _ in range(60)])
    y = np.array((["foot"] * 54 + ["bike"] * 6) * 6)
    X = np.zeros((len(y), 9))
    X[y == "foot"] = rng.normal(0, 0.1, size=(int(np.sum(y == "foot")), 9))
    X[y == "bike"] = rng.normal(5, 0.1, size=(int(np.sum(y == "bike")), 9))

    _, bericht = train(X, y, nutzer, seed=0)
    assert "RandomForestClassifier" in bericht["modell"]
    assert "bike" in bericht["report"]
    assert 0.0 <= bericht["macro_f1_ohne_plane"] <= 1.0


def test_subsample_behaelt_staerksten_beitraeger_je_klasse():
    df = pd.DataFrame({
        "user": ["u1"] * 3 + ["u2"] * 3 + ["u3"] * 3 + ["u4"] * 3,
        "mode": (["car", "foot", "bike"] * 3 + ["plane", "plane", "plane"]),
    })
    teil = subsample_by_user(df, n_users=1, seed=0, top_je_klasse=1)
    assert "u4" in set(teil["user"])
