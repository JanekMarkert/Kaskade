import CoreBluetooth
import CoreLocation
import Foundation

enum BeaconConfig {
    static let uuid = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
    static let major: CLBeaconMajorValue = 1
    static let minor: CLBeaconMinorValue = 1
    static let identifier = "de.bht.traveltracker.beacon"
    static let measuredPower = -59
}

final class BeaconAdvertiser: NSObject, CBPeripheralManagerDelegate {
    private var manager: CBPeripheralManager?

    func start() { manager = CBPeripheralManager(delegate: self, queue: nil) }
    func stop() { manager?.stopAdvertising(); manager = nil }

    func peripheralManagerDidUpdateState(_ p: CBPeripheralManager) {
        guard p.state == .poweredOn else { return }
        let region = CLBeaconRegion(uuid: BeaconConfig.uuid,
                                    major: BeaconConfig.major,
                                    minor: BeaconConfig.minor,
                                    identifier: BeaconConfig.identifier)
        let daten = region.peripheralData(
            withMeasuredPower: NSNumber(value: BeaconConfig.measuredPower))
        p.startAdvertising(daten as? [String: Any])
    }
}
