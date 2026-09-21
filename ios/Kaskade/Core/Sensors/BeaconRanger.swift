import CoreLocation
import Foundation

final class BeaconRanger: NSObject, CLLocationManagerDelegate {
    private let database: AppDatabase
    private let manager = CLLocationManager()
    private var sollDistanz: Double?
    private var los = true
    var onRecorded: (() -> Void)?
    private(set) var samples: [BeaconSample] = []

    init(database: AppDatabase) {
        self.database = database
        super.init()
        manager.delegate = self
    }

    func setTruth(distance: Double, los: Bool) {
        self.sollDistanz = distance
        self.los = los
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startRangingBeacons(
            satisfying: CLBeaconIdentityConstraint(uuid: BeaconConfig.uuid))
    }

    func stop() {
        manager.stopRangingBeacons(
            satisfying: CLBeaconIdentityConstraint(uuid: BeaconConfig.uuid))
    }

    func locationManager(_ m: CLLocationManager, didRange beacons: [CLBeacon],
                         satisfying c: CLBeaconIdentityConstraint) {
        for b in beacons { record(rssi: b.rssi, clAccuracy: b.accuracy) }
    }

    func record(rssi: Int, clAccuracy: Double) {
        guard let soll = sollDistanz, rssi != 0 else { return }
        var sample = BeaconSample(id: nil, ts: Date().timeIntervalSince1970,
                                  uuid: BeaconConfig.uuid.uuidString,
                                  major: Int(BeaconConfig.major),
                                  minor: Int(BeaconConfig.minor),
                                  rssi: rssi,
                                  clAccuracy: clAccuracy >= 0 ? clAccuracy : nil,
                                  trueDistance: soll, los: los)
        do {
            try database.writer.write { try sample.insert($0) }
            samples.append(sample)
            onRecorded?()
        } catch {}
    }
}
