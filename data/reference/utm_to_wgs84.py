"""UTM33/ETRS89 (EPSG:25833) Koordinate aus FIS-Broker nach WGS84 umrechnen.

Verwendung: python utm_to_wgs84.py <ost> <nord>
"""
import sys

from pyproj import Transformer

_transformer = Transformer.from_crs("EPSG:25833", "EPSG:4326", always_xy=True)


def utm_to_wgs84(ost: float, nord: float) -> tuple[float, float]:
    lon, lat = _transformer.transform(ost, nord)
    return lat, lon


if __name__ == "__main__":
    ost, nord = float(sys.argv[1]), float(sys.argv[2])
    lat, lon = utm_to_wgs84(ost, nord)
    print(f"lat={lat:.7f} lon={lon:.7f}")
