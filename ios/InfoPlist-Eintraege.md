# Info.plist — Einträge für Kaskade

In Xcode über Target → Info eintragen, oder die Quelltextfassung unten in die
Info.plist einfügen (Rechtsklick auf die Datei → Open As → Source Code).

## Als Tabelle (Xcode-Oberfläche)

| Key | Typ | Wert |
|---|---|---|
| Privacy - Location When In Use Usage Description | String | Zeichnet die Route deiner Reise auf. |
| Privacy - Location Always and When In Use Usage Description | String | Zeichnet die Route auch bei ausgeschaltetem Bildschirm auf. |
| Privacy - Motion Usage Description | String | Erkennt anhand der Bewegung das Verkehrsmittel. |
| Privacy - Bluetooth Always Usage Description | String | Misst die Entfernung zu einem zweiten Gerät über Bluetooth. |
| Privacy - Nearby Interaction Usage Description | String | Misst die Entfernung zu einem zweiten Gerät über Ultrabreitband. |
| Privacy - Camera Usage Description | String | Misst Entfernungen mit dem LiDAR-Scanner. |
| Privacy - Local Network Usage Description | String | Findet das zweite Messgerät im lokalen Netz. |
| Required background modes | Array | `location`, `bluetooth-peripheral` |

## Als Quelltext

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Zeichnet die Route deiner Reise auf.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Zeichnet die Route auch bei ausgeschaltetem Bildschirm auf.</string>
<key>NSMotionUsageDescription</key>
<string>Erkennt anhand der Bewegung das Verkehrsmittel.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Misst die Entfernung zu einem zweiten Gerät über Bluetooth.</string>
<key>NSNearbyInteractionUsageDescription</key>
<string>Misst die Entfernung zu einem zweiten Gerät über Ultrabreitband.</string>
<key>NSCameraUsageDescription</key>
<string>Misst Entfernungen mit dem LiDAR-Scanner.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Findet das zweite Messgerät im lokalen Netz.</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>bluetooth-peripheral</string>
</array>
```

## Wofür welcher Eintrag gebraucht wird

`NSLocationWhenInUse…` und `…AlwaysAndWhenInUse…` — Task 4, Tracking, und der
Feldtest mit ausgeschaltetem Bildschirm.
`NSMotionUsageDescription` — Task 4, `CMMotionManager` und `CMMotionActivityManager`.
`NSBluetoothAlwaysUsageDescription` — Task 24, iBeacon senden und ranging.
`NSNearbyInteractionUsageDescription` — Task 23, UWB.
`NSLocalNetworkUsageDescription` — Task 23, MultipeerConnectivity für den
Token-Austausch. Ohne diesen Eintrag findet Gerät A Gerät B nicht, und die
Fehlermeldung nennt den Grund nicht.
`NSCameraUsageDescription` — Task 26, ARKit.
`UIBackgroundModes` — Aufzeichnung bei gesperrtem Bildschirm.
