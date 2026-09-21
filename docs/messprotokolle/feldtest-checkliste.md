# Checkliste vor jeder Messung/jedem Feldtest

Auf **jedem** beteiligten Gerät vor dem Losfahren prüfen:

- [ ] Standortfreigabe der App auf „Immer" (nicht nur „beim Verwenden")
- [ ] Bewegungs- und Fitnessdaten für die App freigegeben
- [ ] Hintergrundaktualisierung für die App an
- [ ] Energiesparmodus **aus** (drosselt sonst Sensor-Updates)
- [ ] Mindestens 8 GB freier Speicher
- [ ] Akku über 50 % oder Powerbank + Kabel dabei
- [ ] Uhrzeit über das Netz synchronisiert (Einstellungen → Allgemein → Datum & Uhrzeit → automatisch)
- [ ] App einmal kurz gestartet, „Aufzeichnung starten" getippt, nach 10 Sekunden wieder gestoppt —
      prüft, dass Fixes ankommen (Route erscheint auf der Karte)

## Kurzer Probelauf (vor dem eigentlichen Feldtest)

Einmal 5–10 Minuten losgehen, dabei einmal das Label in der Leiste wechseln,
dann stoppen. Auf der Karte muss eine eingefärbte Route erscheinen. Klappt
das nicht, vor der eigentlichen Messung erst das Problem beheben (fehlende
Berechtigung ist die häufigste Ursache).

## Für die M1-Referenzmessung (Task 8/9) zusätzlich

- [ ] Die drei Referenzpunkte (p1/p2/p3) sind angelaufen und die Koordinaten
      in `data/reference/HERKUNFT.md` eingetragen (siehe dortige Vorlage)
- [ ] Ruler-Symbol oben rechts in der App öffnet die M1-Messansicht
- [ ] Für jeden Punkt: Punkt in der Segmented-Control auswählen, Start,
      10 Minuten ruhig auf der Markierung liegen lassen, Stopp, CSV über
      „CSV exportieren" teilen (z. B. per AirDrop/Mail an sich selbst)
- [ ] Je Punkt drei Sessions à 10 Minuten, über den Tag verteilt — macht
      neun CSV-Dateien insgesamt
- [ ] Dateien landen unter `data/measurements/m1_static/` (Ordner ggf.
      anlegen), Dateiname z. B. `p1_session1.csv`

## Für einen vollständigen Feldtest (Task 18) zusätzlich

- [ ] Route mit mindestens vier Verkehrsmitteln geplant, je Modus mindestens
      15 Minuten am Stück, zwei Stopps über 3 Minuten dazwischen
- [ ] **Zug/Bahn möglichst dabei** — `CMMotionActivity`, die Systembaseline
      aus M2, kennt Zug gar nicht als Kategorie. Ohne Zug im Datensatz fehlt
      genau der Vergleich, der M2 interessant macht
- [x] ~~M1-Punkt p3 neu messen~~ — erledigt sich von selbst: der 59 m-Versatz
      lag am ungenau gesetzten Kartenpunkt, nicht an der Messung. Zwei
      unabhängige Sessions (inkl. der zuvor fälschlich als p1 gelabelten)
      konvergierten auf denselben Fleck; Referenzkoordinate in
      `data/reference/reference_points.geojson` entsprechend korrigiert.
      p3 hat jetzt n=42 über zwei Sessions, noch eine dritte 10-Minuten-
      Session wäre schön, ist aber kein Blocker mehr
- [ ] Beide Geräte zeichnen parallel auf, gleicher Label-Verlauf
- [ ] Die App klassifiziert Move-Segmente jetzt automatisch (Core-ML-Modell,
      seit Task 13/16 fertig) — die Karte färbt trotzdem nach eurem
      Handlabel, nicht nach der Vorhersage (`color_mode` bevorzugt
      `label_mode`). Die Modellvorhersage (`predicted_mode`) wird im
      Hintergrund mitgespeichert, für den späteren Vergleich in Task 19.

## Für M3 (UWB/BLE, Task 25) und M4 (LiDAR, Task 26)

Eigene, ausführliche Protokolle: `docs/messprotokolle/m3.md` und
`docs/messprotokolle/m4.md`. Kurzfassung:

- [ ] M3: zwei Geräte, eins als „Anker" (UWB-Knopf → Rolle Anker → Start,
      hinstellen und liegen lassen), eins als „Messgerät" (UWB-Knopf → Rolle
      Messgerät, misst UWB **und** BLE gleichzeitig, exportiert eine
      kombinierte CSV)
- [ ] M4: LiDAR-Knopf, braucht ein Pro-iPhone mit LiDAR-Scanner — App zeigt
      "nicht verfügbar" an, falls das Gerät keins hat
