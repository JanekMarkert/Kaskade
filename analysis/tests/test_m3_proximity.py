import pandas as pd
from evaluation.m3_proximity import error_by_distance


def test_bias_und_mae_werden_getrennt_ausgewiesen():
    df = pd.DataFrame({
        "verfahren": ["uwb"] * 4,
        "true_distance": [2.0, 2.0, 2.0, 2.0],
        "gemessen": [2.1, 2.1, 1.9, 1.9],
        "los": [True] * 4,
    })
    out = error_by_distance(df, "uwb")
    zeile = out.iloc[0]
    assert abs(zeile["bias_m"]) < 1e-9
    assert abs(zeile["mae_m"] - 0.1) < 1e-9
    assert zeile["n"] == 4


def test_trennt_nach_sichtbedingung():
    df = pd.DataFrame({
        "verfahren": ["uwb"] * 4,
        "true_distance": [2.0] * 4,
        "gemessen": [2.0, 2.0, 3.0, 3.0],
        "los": [True, True, False, False],
    })
    out = error_by_distance(df, "uwb")
    assert len(out) == 2
    nlos = out[~out["los"]].iloc[0]
    assert abs(nlos["bias_m"] - 1.0) < 1e-9
