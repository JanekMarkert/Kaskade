# Track-GeoJSON

FeatureCollection, WGS84 (EPSG:4326), Koordinatenreihenfolge [lon, lat].

Ein Feature je Segment, Geometrie LineString.

Properties je Feature:
- `segment_id`      Integer
- `kind`            "stop" | "move"
- `predicted_mode`  "foot" | "bike" | "car" | "train" | "plane" | null
- `confidence`      Float 0..1 oder null
- `label_mode`      Ground Truth aus dem Feldtest, gleiche Werte, oder null
- `start_ts`        Unix-Sekunden, Float
- `end_ts`          Unix-Sekunden, Float
- `timestamps`      Array von Unix-Sekunden, gleiche Länge wie coordinates
- `h_acc`           Array der gemeldeten Genauigkeiten in Metern, gleiche Länge
- `alt`             Array der Höhen in Metern, gleiche Länge; 0 wo CoreLocation
                    keine Höhe lieferte

Die parallelen Arrays `timestamps`, `h_acc` und `alt` machen den Replay im
Viewer und die Auswertung in Python ohne Zugriff auf die SQLite-Datei möglich.
`alt` geht als Steigrate in die Klassifikation ein -- ohne sie lässt sich die
Modellvorhersage außerhalb der App nicht nachrechnen.
