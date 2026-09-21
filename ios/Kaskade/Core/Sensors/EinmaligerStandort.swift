import CoreLocation

/// Holt einmalig die aktuelle Position, z. B. um eine UWB- oder
/// LiDAR-Messung geo-zu-referenzieren — kein fortlaufendes Tracking wie
/// `TrackingService`.
final class EinmaligerStandort: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var abschluss: ((CLLocationCoordinate2D?) -> Void)?

    func hole(_ abschluss: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.abschluss = abschluss
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        abschluss?(locations.last?.coordinate)
        abschluss = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        abschluss?(nil)
        abschluss = nil
    }
}
