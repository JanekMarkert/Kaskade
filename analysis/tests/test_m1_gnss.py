import numpy as np
import pandas as pd
from evaluation.m1_gnss import cep, error_series


def test_cep_gibt_quantil_der_fehler():
    fehler = np.arange(1, 101, dtype=float)
    assert abs(cep(fehler, 0.5) - 50.5) < 1.0
    assert abs(cep(fehler, 0.95) - 95.0) < 1.5


def test_error_series_rechnet_meter_nicht_grad():
    df = pd.DataFrame({"lat": [52.5451], "lon": [13.3550], "h_acc": [5.0]})
    ref = {"lat": 52.5450, "lon": 13.3550}
    fehler = error_series(df, ref)
    assert 10.0 < fehler[0] < 12.0


def test_error_series_beruecksichtigt_laengengradstauchung():
    df = pd.DataFrame({"lat": [52.5450], "lon": [13.3551], "h_acc": [5.0]})
    ref = {"lat": 52.5450, "lon": 13.3550}
    fehler = error_series(df, ref)
    assert 6.0 < fehler[0] < 7.5
