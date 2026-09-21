"""Pfade relativ zum Repository-Wurzelverzeichnis, unabhängig vom Arbeitsverzeichnis."""
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DATA = REPO / "data"
DOCS = REPO / "docs"
ANALYSIS = REPO / "analysis"
