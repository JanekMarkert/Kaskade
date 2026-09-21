import Testing
@testable import Kaskade

@Test func m3CsvKombiniertUwbUndBleMitVerfahrensspalte() {
    let uwb = [UWBSample(id: nil, ts: 1, peer: "p", distance: 2.05,
                         dirX: nil, dirY: nil, dirZ: nil,
                         trueDistance: 2.0, los: true)]
    let ble = [BeaconSample(id: nil, ts: 2, uuid: "u", major: 1, minor: 1,
                            rssi: -70, clAccuracy: 2.4,
                            trueDistance: 2.0, los: true)]
    let csv = M3CSV.build(uwb: uwb, ble: ble)
    let zeilen = csv.split(separator: "\n", omittingEmptySubsequences: false)
    #expect(zeilen[0] == "verfahren,true_distance,gemessen,los")
    #expect(zeilen[1] == "uwb,2.0,2.05,true")
    #expect(zeilen[2] == "ble,2.0,2.4,true")
}
