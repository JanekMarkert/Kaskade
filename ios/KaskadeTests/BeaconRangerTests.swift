import Testing
@testable import Kaskade

@Test func schreibtRssiUndAppleSchaetzungMitSollwert() throws {
    let db = try AppDatabase.makeInMemory()
    let ranger = BeaconRanger(database: db)
    ranger.setTruth(distance: 5.0, los: false)
    ranger.record(rssi: -72, clAccuracy: 6.4)

    let samples = try db.reader.read { try BeaconSample.fetchAll($0) }
    #expect(samples.count == 1)
    #expect(samples[0].rssi == -72)
    #expect(abs((samples[0].clAccuracy ?? 0) - 6.4) < 1e-6)
    #expect(samples[0].los == false)
}

@Test func verwirftUngueltigenRssi() throws {
    let db = try AppDatabase.makeInMemory()
    let ranger = BeaconRanger(database: db)
    ranger.setTruth(distance: 5.0, los: true)
    ranger.record(rssi: 0, clAccuracy: -1)
    let samples = try db.reader.read { try BeaconSample.fetchAll($0) }
    #expect(samples.isEmpty)
}
