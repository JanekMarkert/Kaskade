import pandas as pd
from evaluation.m4_lidar import error_by_distance, LOW_CONFIDENCE


def test_verwirft_messungen_mit_niedriger_konfidenz():
    df = pd.DataFrame({
        "true_distance": [2.0] * 4,
        "depth_m": [2.0, 2.0, 9.9, 9.9],
        "confidence": [2, 2, LOW_CONFIDENCE, LOW_CONFIDENCE],
        "lighting": ["tag"] * 4,
    })
    out = error_by_distance(df)
    assert out.iloc[0]["n"] == 2
    assert abs(out.iloc[0]["mae_m"]) < 1e-9


def test_trennt_nach_beleuchtung():
    df = pd.DataFrame({
        "true_distance": [2.0] * 4,
        "depth_m": [2.01, 2.01, 2.30, 2.30],
        "confidence": [2] * 4,
        "lighting": ["tag", "tag", "nacht", "nacht"],
    })
    out = error_by_distance(df)
    assert len(out) == 2
    nacht = out[out["lighting"] == "nacht"].iloc[0]
    assert abs(nacht["mae_m"] - 0.30) < 1e-6
