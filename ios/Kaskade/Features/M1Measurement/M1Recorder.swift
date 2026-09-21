import CoreLocation
import Foundation

/// Eigenständiger Rekorder nur für die M1-Referenzmessung — schreibt bewusst
/// nicht in die App-Datenbank, sondern hält Fixes im Speicher bis zum Export.
final class M1Recorder: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published private(set) var fixes: [M1Fix] = []
    @Published private(set) var isRecording = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }

    func start() {
        fixes = []
        isRecording = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func stop() {
        isRecording = false
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard isRecording else { return }
        for loc in locs where loc.horizontalAccuracy >= 0 {
            fixes.append(M1Fix(ts: loc.timestamp.timeIntervalSince1970,
                               lat: loc.coordinate.latitude,
                               lon: loc.coordinate.longitude,
                               hAcc: loc.horizontalAccuracy))
        }
    }
}
