import textwrap
from geolife.prepare import parse_plt, parse_labels, MODE_MAP

def test_parse_plt_ueberspringt_kopfzeilen_und_rechnet_fuss_in_meter(tmp_path):
    p = tmp_path / "t.plt"
    p.write_text(textwrap.dedent("""\
        Geolife trajectory
        WGS 84
        Altitude is in Feet
        Reserved 3
        0,2,255,My Track,0,0,2
        0
        39.984702,116.318417,0,492,39744.245,2008-10-23,05:53:05
        39.984683,116.318450,0,492,39744.245,2008-10-23,05:53:06
        """))
    df = parse_plt(p)
    assert len(df) == 2
    assert abs(df["alt_m"].iloc[0] - 149.9) < 0.5   # 492 Fuß
    assert df["ts"].iloc[1] - df["ts"].iloc[0] == 1.0

def test_parse_labels_liest_tabgetrennte_zeitspannen(tmp_path):
    p = tmp_path / "labels.txt"
    p.write_text("Start Time\tEnd Time\tTransportation Mode\n"
                 "2008/04/02 11:24:21\t2008/04/02 11:50:45\tbus\n")
    df = parse_labels(p)
    assert len(df) == 1
    assert df["mode"].iloc[0] == "bus"
    assert df["end_ts"].iloc[0] > df["start_ts"].iloc[0]

def test_mode_map_fasst_oepnv_zu_train_zusammen():
    assert MODE_MAP["subway"] == "train"
    assert MODE_MAP["taxi"] == "car"
    assert "boat" not in MODE_MAP
