import numpy as np
import pytest
from evaluation.m2_classifier import confusion, map_cm_activity, load_all_tracks, KLASSEN


def test_baseline_kann_zug_und_flug_nicht_treffen():
    assert map_cm_activity("automotive") == "car"
    assert map_cm_activity("walking") == "foot"
    assert map_cm_activity("cycling") == "bike"
    zustaende = ["walking", "running", "cycling", "automotive", "stationary", "unknown"]
    assert "train" not in {map_cm_activity(z) for z in zustaende}
    assert "plane" not in {map_cm_activity(z) for z in zustaende}


def test_confusion_hat_form_klassen_mal_klassen():
    y_true = ["foot", "car", "train", "foot"]
    y_pred = ["foot", "car", "car", "bike"]
    m = confusion(y_true, y_pred, KLASSEN)
    assert m.shape == (len(KLASSEN), len(KLASSEN))
    assert m[KLASSEN.index("foot"), KLASSEN.index("foot")] == 1
    assert m[KLASSEN.index("train"), KLASSEN.index("car")] == 1


def test_load_all_tracks_wirft_ohne_dateien(tmp_path):
    with pytest.raises(FileNotFoundError):
        load_all_tracks(tmp_path)
