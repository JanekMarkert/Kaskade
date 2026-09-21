import importlib

import paths


def test_pfade_bleiben_bei_wechsel_des_arbeitsverzeichnisses_gleich(monkeypatch, tmp_path):
    repo_referenz = paths.REPO
    monkeypatch.chdir(tmp_path)
    importlib.reload(paths)
    assert paths.REPO == repo_referenz
    assert paths.DATA.is_dir()
    assert paths.DOCS.is_dir()


def test_repo_ist_das_tatsaechliche_repository_wurzelverzeichnis():
    assert (paths.REPO / ".git").is_dir()
    assert (paths.REPO / "analysis" / "requirements.txt").is_file()
    assert (paths.REPO / "docs" / "abgabe").is_dir()
