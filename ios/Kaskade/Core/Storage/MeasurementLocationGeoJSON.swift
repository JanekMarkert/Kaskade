import CoreLocation
import Foundation

/// Schreibt den Standort einer Messung (UWB, LiDAR) als einzelnes
/// GeoJSON-Feature — die Dateien einer Sitzung werden von `MeasurementMapView`
/// wieder eingesammelt und als Punkte auf der Karte angezeigt.
enum MeasurementLocationGeoJSON {
    static func punkt(koordinate: CLLocationCoordinate2D, name: String) -> Data {
        let dict: [String: Any] = [
            "type": "Feature",
            "properties": ["name": name],
            "geometry": ["type": "Point", "coordinates": [koordinate.longitude, koordinate.latitude]],
        ]
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }
}
