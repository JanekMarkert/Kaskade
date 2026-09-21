# Task 2 — Xcode-Projekt anlegen

Diese Schritte macht ein Mensch in der Xcode-Oberfläche. Danach prüft
`./ios/verify-setup.sh`, ob alles sitzt.

## 1. Projekt anlegen

File → New → Project → iOS → **App**

| Feld | Wert |
|---|---|
| Product Name | `Kaskade` |
| Team | dein Apple-Account (für Gerätetests nötig) |
| Organization Identifier | `de.bht` |
| Bundle Identifier | ergibt `de.bht.messkaskade` — danach in den Build Settings auf `de.bht.messkaskade` ändern |
| Interface | SwiftUI |
| Language | Swift |
| Testing System | **Swift Testing** (nicht XCTest) |
| Storage | None |
| Create Git repository | **aus** — das Repo existiert schon |

Speicherort: der Ordner `ios/` in diesem Repository. Ergebnis muss sein:
`ios/Kaskade.xcodeproj` und daneben `ios/Kaskade/`.

Dann im Target unter General das **Minimum Deployment** auf **iOS 17.0** setzen.

## 2. Pakete hinzufügen

File → Add Package Dependencies…

| Paket | URL | Regel |
|---|---|---|
| GRDB | `https://github.com/groue/GRDB.swift` | Up to Next Major, ab `7.0.0` |
| MapLibre | `https://github.com/maplibre/maplibre-gl-native-distribution` | Up to Next Major, ab `6.0.0` |

Beide dem Target `Kaskade` zuordnen. Löst eine Major-Version nicht auf,
die höchste verfügbare nehmen und die gewählte Version unten in
„Abweichungen" eintragen.

## 3. Berechtigungen

Target → Info. Die Einträge stehen paste-fertig in
[InfoPlist-Eintraege.md](InfoPlist-Eintraege.md). Sieben Texte plus
`UIBackgroundModes`.

Zwei davon werden gern vergessen und fallen erst in Task 23 auf, wenn ihr mit
zwei Geräten im Flur steht: `NSNearbyInteractionUsageDescription` für UWB und
`NSLocalNetworkUsageDescription` für den Token-Austausch zwischen den Geräten.

## 4. Ordnerstruktur

In Xcode als **Groups mit Ordnerbezug** anlegen (Rechtsklick → New Group with
Folder), damit die Dateien auch auf der Platte so liegen:

```
Kaskade/
  Core/
    Tracking/        Task 4
    Storage/         Task 3, 5
    Sensors/         Task 23, 24, 26
    Segmentation/    Task 7, 15
    Classification/  Task 14, 16
  Features/
    MapView/         Task 6
    TripList/        Task 21
    LabelBar/        Task 15
    ProximityLab/    Task 23, 24
    DepthLab/        Task 26
  Resources/         Task 16 (TransportMode.mlmodel)
```

## 6. Prüfen

```bash
./ios/verify-setup.sh
```

Läuft das durch, ist Task 2 fertig und Task 3 (Datenbankschema) kann starten.

## Abweichungen

Trage hier ein, was du anders machen musstest:

- GRDB-Version:
- MapLibre-Version:
- Sonstiges:
