import pandas as pd
from evaluation.cascade import gewichteter_gnss_fehler


def test_gewichteter_gnss_fehler_gewichtet_nach_n():
    m1 = pd.DataFrame({"cep95_m": [10.0, 20.0], "n": [90, 10]})
    # 90% Gewicht auf 10.0, 10% auf 20.0 -> nahe 11.0
    assert abs(gewichteter_gnss_fehler(m1) - 11.0) < 0.01


def test_gewichteter_gnss_fehler_gleiches_gewicht():
    m1 = pd.DataFrame({"cep95_m": [10.0, 20.0], "n": [1, 1]})
    assert abs(gewichteter_gnss_fehler(m1) - 15.0) < 0.01
