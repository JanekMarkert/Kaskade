# GeoLife-Aufbereitung

`prepare.py` überführt GeoLife Trajectories 1.3 in ein gelabeltes DataFrame
(`build_dataset`), das Task 12/13 als Trainingsgrundlage dient.

## Datenquelle

GeoLife Trajectories 1.3, Microsoft Research. 182 Nutzer, davon 69 mit
Transportmodus-Labels.

- Downloadseite: https://www.microsoft.com/en-us/download/details.aspx?id=52367
- Direkte Datei: https://download.microsoft.com/download/f/4/8/f4894aa5-fdbc-481e-9285-d5f8c4c4f039/Geolife%20Trajectories%201.3.zip
- Umfang: rund 300 MB.

## Ablage

Das Archiv wird nach `analysis/geolife/raw/` entpackt. Der Ordner steht in
`.gitignore` und wird nicht mitversioniert — das ist beabsichtigt, sonst
sucht jemand die Rohdaten im Repository, statt sie selbst herunterzuladen.

## `.plt`-Format

Sechs Kopfzeilen, danach je Zeile:

```
lat,lon,0,alt_in_fuss,tage_seit_1899-12-30,datum,zeit
```

Die Höhe steht in Fuß. `prepare.py` rechnet sie mit dem Faktor `0.3048`
(Konstante `FUSS_IN_METER`) in Meter um.

## `labels.txt`-Format

Tabgetrennt, mit den Spalten `Start Time`, `End Time`, `Transportation
Mode`. Diese Datei liegt nur bei den 69 Nutzern mit Transportmodus-Labels
vor.

## Modus-Abbildung

`MODE_MAP` faltet GeoLifes Modus-Strings auf die fünf Zielklassen:

| GeoLife | Zielklasse |
|---|---|
| walk, run | foot |
| bike | bike |
| car, taxi, bus | car |
| train, subway, railway | train |
| airplane | plane |
| boat, motorcycle | verworfen |

`boat` und `motorcycle` fehlen bewusst in `MODE_MAP`. Trajektorien mit
diesen Modi werden in `build_dataset` verworfen, nicht auf eine der fünf
Klassen geraten.

## Ergebnis des Laufs über den echten Korpus

`build_dataset('geolife/raw/Geolife Trajectories 1.3/Data')`:

| Klasse | Punkte |
|---|---|
| bike | 952 975 |
| car | 2 035 896 |
| foot | 1 585 078 |
| plane | 9 174 |
| train | 871 118 |

Punkte gesamt: 5 454 241. Laufzeit: 861 s. Spitzen-RSS: 995 MB.
`dataset.parquet`: 87 MB (nicht versioniert, siehe `.gitignore`).

**Beitragende Nutzer: 56, nicht 69.** Dreizehn der 69 gelabelten Nutzer
tragen nichts zum Datensatz bei — entweder haben sie nur Labels, die
`MODE_MAP` verwirft (`boat`, `motorcycle`), oder ihre gelabelten
Zeitspannen enthalten weniger als 60 Punkte.

**`plane` ist stark unterrepräsentiert.** 9 174 Punkte entsprechen rund
0,17 % aller Punkte; `car` hat rund 222-mal so viele Punkte wie `plane`.
Die Klasse bleibt im Modell — die im Plan genannte Untergrenze lag bei
2 000 Punkten, `plane` liegt darüber —, aber die Schieflage ist erheblich:
die `plane`-Zeile einer späteren Konfusionsmatrix beruht auf entsprechend
wenigen Fenstern.

`build_dataset` ist damit sowohl durch Unit-Tests mit synthetischen
Fixtures (`analysis/tests/test_prepare.py`) als auch durch diesen Lauf
über den echten Korpus abgedeckt.
