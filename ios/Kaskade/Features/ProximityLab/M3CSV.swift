import Foundation

enum M3CSV {
    static func build(uwb: [UWBSample], ble: [BeaconSample]) -> String {
        var zeilen = ["verfahren,true_distance,gemessen,los"]
        for s in uwb {
            guard let gemessen = s.distance else { continue }
            zeilen.append("uwb,\(s.trueDistance),\(gemessen),\(s.los)")
        }
        for s in ble {
            guard let gemessen = s.clAccuracy else { continue }
            zeilen.append("ble,\(s.trueDistance),\(gemessen),\(s.los)")
        }
        return zeilen.joined(separator: "\n")
    }
}
