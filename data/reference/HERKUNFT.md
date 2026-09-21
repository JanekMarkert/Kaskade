# Herkunft der Referenzpunkte für M1

Quelle: ALKIS Berlin Gebäude, WFS-Dienst des Landes Berlin
(`https://gdi.berlin.de/services/wfs/alkis_gebaeude`, Feature-Type
`alkis_gebaeude:gebaeude`), Datenlizenz Deutschland – Namensnennung 2.0.
Koordinaten automatisch per `data/reference/fetch_alkis_corner.py <lat> <lon>`
abgerufen (nächste Gebäudeecke zu einer Näherungskoordinate) statt manuell
im FIS-Broker-Kartenviewer nachgeschlagen — spart den Weg über die
interaktive Karte. **Ersetzt nicht** die Vor-Ort-Verifikation: Foto der
Markierung ist weiterhin Pflicht.

Für jeden Punkt eintragen, sobald vor Ort erhoben:

## p1 — BHT-Campus Wedding, Gebäudeecke in enger Straße (`urban_canyon`)

- Datensatzname: ALKIS Berlin Gebäude (WFS), Feature `gebaeude.DEBE01AL1rt00001`
- Abrufdatum: 2026-09-11 (automatisch, noch nicht vor Ort verifiziert)
- UTM33 (Ost, Nord): 388337.48, 5822781.228
- WGS84 (lat, lon): 52.5436505, 13.3533855
- Foto: `data/reference/fotos/p1.jpg` — **noch ausstehend**, am Sonntag
  diese Gebäudeecke aufsuchen (nahe Luxemburger Str. 10, BHT Campus Wedding),
  mit dem Kataster-/Grundriss abgleichen, fotografieren

## p2 — Rummelsburger Ufer, freistehendes Bauwerk am Wasser (`open_sky`)

Vom Team vorgegebener Standort (Google-Maps-Pin), nicht Tempelhofer Feld —
Hauptstraße/Rummelsburger Ufer, Rummelsburg, Lichtenberg, direkt am Wasser
mit freiem Himmelsblick.

- Datensatzname: ALKIS Berlin Gebäude (WFS), Feature `gebaeude.DEBE11YYI0000If5`
- Abrufdatum: 2026-09-11 (automatisch, noch nicht vor Ort verifiziert)
- UTM33 (Ost, Nord): 396605.996, 5817731.455
- WGS84 (lat, lon): 52.4999012, 13.476838
- Foto: `data/reference/fotos/p2.jpg` — **noch ausstehend**, Gebäudeecke ca.
  21 m vom vorgegebenen Pin entfernt, vor Ort mit Kataster/Grundriss
  abgleichen, fotografieren

## p3 — Innenhof „Grüne Stadt", umlaufende Bebauung (`shadowed`)

Vom Team vorgegebener Standort (Google-Maps-Pin) — Kniprodestraße, Grüne
Stadt, Prenzlauer Berg, eine Wohnanlage mit Innenhöfen.

- Datensatzname: ALKIS Berlin Gebäude (WFS), Feature `gebaeude.DEBE03YY600009bA`
- Abrufdatum: 2026-09-11 (automatisch, noch nicht vor Ort verifiziert)
- UTM33 (Ost, Nord): 394145.076, 5821301.611
- WGS84 (lat, lon): 52.5315135, 13.4394625
- Foto: `data/reference/fotos/p3.jpg` — **noch ausstehend**, Gebäudeecke ca.
  27 m vom vorgegebenen Pin entfernt, vor Ort mit Kataster/Grundriss
  abgleichen, fotografieren

## Rückfallebene

Falls sich innerhalb eines halben Tages keine belastbare Referenzkoordinate
beschaffen lässt: M1 auf Wiederholgenauigkeit umstellen (Streuung der Fixes
um ihren eigenen Mittelwert je Standort, verglichen mit der gemeldeten
`horizontalAccuracy`). Hier eintragen, ob und für welche Punkte das nötig war.
