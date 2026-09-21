# Ablaufplan Sonntag — Messungen M1, M3, M4

Voraussetzung: App ist auf beiden Handys installiert und einmal gestartet
(siehe „Geräte verbinden" unten). Detaillierte Positions-/Distanztabellen
zum Ausfüllen stehen in `m1.md`, `m3.md`, `m4.md` — dies hier ist die
Reihenfolge und die technische Bedienung.

## 0. Vorbereitung zuhause (einmalig, vor dem Losfahren)

Für **jedes** Gerät:

1. Xcode → Einstellungen → Accounts → eigene Apple-ID hinzufügen (falls noch
   nicht geschehen)
2. iPhone per Kabel anschließen, in Xcode als Zielgerät auswählen
3. `Kaskade`-Target → „Signing & Capabilities" → „Automatically manage
   signing" → eigene Apple-ID als Team wählen
4. ▶️ (Run) drücken — installiert und startet die App
5. Auf dem iPhone: Einstellungen → Allgemein → VPN & Geräteverwaltung →
   Entwicklerprofil antippen → „Vertrauen"
6. App einmal öffnen, alle Berechtigungsanfragen mit „Erlauben" bzw. „Immer
   erlauben" bestätigen (Standort, Bewegung, Bluetooth, lokales Netzwerk,
   bei LiDAR-Gerät zusätzlich Kamera)
7. Checkliste in `feldtest-checkliste.md` durchgehen (Energiesparmodus aus,
   Uhrzeit synchronisiert, genug Speicher)

Ab hier läuft die App eigenständig über das Icon, kein Kabel/Xcode mehr
nötig — bis zur automatischen 7-Tage-Frist der kostenlosen Signierung.

## Geräte verbinden — was dahintersteckt

**Es gibt kein manuelles Bluetooth-Pairing.** UWB und BLE koppeln sich
automatisch, sobald beide Handys:
- die App offen haben (im UWB-Screen bzw. entsprechend als Anker/Messgerät),
- Bluetooth und WLAN an haben,
- nah beieinander sind (ein paar Meter reichen).

Die App tauscht die nötigen Kopplungsdaten selbst über Apples
Multipeer-Framework aus (läuft automatisch über Bluetooth/WLAN im
Hintergrund). Beim allerersten Kontakt kann iOS kurz einen
Systemdialog „X möchte Geräte in deinem lokalen Netzwerk finden" zeigen —
mit „OK" bestätigen. Falls nach ca. 10 Sekunden keine Kopplung
zustande kommt: beide Apps einmal schließen (nach oben wischen) und neu
öffnen, dann Start erneut drücken.

## 1. M1 — GNSS-Genauigkeit (kein zweites Gerät nötig)

Jedes Gerät für sich, an den drei Punkten aus `m1.md`.

1. App öffnen → Lineal-Symbol „M1"
2. Punkt (p1/p2/p3) auswählen → Start → Handy **flach auf der Markierung**
   liegen lassen, Bildschirm an, am Ladegerät
2. Nach 10 Minuten selbst stoppen (kein Auto-Stopp bei M1)
3. „Fertig" oben rechts schließt den Screen, „CSV exportieren" schickt die
   Datei per AirDrop/Mail an euch
4. Wiederholen: 3 Sessions je Punkt → 9 Dateien

## 2. M3 — UWB + BLE (zwei Geräte)

1. **Gerät A (bleibt stehen):** UWB-Symbol → Rolle „Anker" → Start.
   Auf Stativ/Stuhl ablegen, App offen lassen, nicht mehr anfassen.
2. **Gerät B (wird bewegt):** UWB-Symbol → Rolle „Messgerät" bleibt
   ausgewählt.
3. Für jede der 7 Distanzen aus `m3.md`, zweimal (LOS/NLOS):
   - Abstand mit Maßband abmessen, Solldistanz eintragen
   - „Freie Sicht (LOS)" richtig setzen
   - Start → App stoppt automatisch nach 60 UWB-Messungen (BLE läuft
     parallel mit)
   - „CSV exportieren (UWB + BLE)" → Datei sichern
4. 14 Durchgänge, 14 Dateien. Gerät A läuft die ganze Zeit als Anker weiter.
5. Zum Schluss auf Gerät A ebenfalls „Fertig" antippen.

## 3. M4 — LiDAR (nur auf dem Pro-iPhone)

Vorher prüfen: LiDAR-Symbol öffnen, steht dort „nicht verfügbar", geht
diese Messung auf diesem Gerät nicht — nur auf dem iPhone 17 Pro Max.

1. LiDAR-Symbol → Solldistanz eintragen → Tag/Nacht wählen
2. Matte, ebene Fläche vor das Gerät stellen, Abstand mit Maßband messen
3. Fadenkreuz auf die Fläche halten, ruhig halten, Start — stoppt
   automatisch nach 30 Messungen
4. „CSV exportieren" → Datei sichern
5. Für die 7 Distanzen aus `m4.md`, je einmal Tag und einmal Nacht (Nacht
   kann auch am Abend nachgeholt werden) → 14 Dateien

## Danach (kein Feldeinsatz mehr nötig)

Alle CSVs an mich schicken (AirDrop an den Mac reicht) plus die
ausgefüllten Protokolltabellen aus `m1.md`/`m3.md`/`m4.md`. Ich lege die
Dateien an die richtige Stelle (`data/measurements/...`) und lasse die
Python-Auswertungen laufen (`m1_gnss.py`, `m3_proximity.py`,
`m4_lidar.py`) — das ist reiner Code, dafür müsst ihr nichts mehr tun.

## Wenn etwas nicht klappt

- **App zeigt gar nichts, Karte bleibt leer:** Standortfreigabe fehlt oder
  ist nur „beim Verwenden" statt „Immer" — Einstellungen → App → Standort.
- **UWB/BLE koppeln nicht:** Bluetooth und WLAN auf beiden Geräten an,
  beide Apps neu starten, Geräte näher zusammen.
- **"Nicht verfügbar"-Hinweis bei UWB oder LiDAR:** Hardware-Grenze des
  Geräts, keine Einstellung hilft — iPhone 15 und 17 Pro Max haben beide
  UWB, nur LiDAR braucht ein Pro-Modell.
- **Export-Knopf erscheint nicht:** Es wurden 0 Messungen aufgenommen —
  meist Berechtigung fehlt oder Sensor nicht verfügbar, siehe oben.
