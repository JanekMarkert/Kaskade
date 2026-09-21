import Testing
@testable import Kaskade

@Test func schreibtMessungMitSollwertUndSichtbedingung() throws {
    let db = try AppDatabase.makeInMemory()
    let ranger = UWBRanger(database: db)
    ranger.setTruth(distance: 2.0, los: true)
    ranger.record(distance: 2.07, direction: nil)

    let samples = try db.reader.read { try UWBSample.fetchAll($0) }
    #expect(samples.count == 1)
    #expect(abs(samples[0].trueDistance - 2.0) < 1e-9)
    #expect(samples[0].los == true)
    #expect(abs((samples[0].distance ?? 0) - 2.07) < 1e-6)
}

@Test func verwirftMessungOhneGesetztenSollwert() throws {
    let db = try AppDatabase.makeInMemory()
    let ranger = UWBRanger(database: db)
    ranger.record(distance: 2.07, direction: nil)
    let samples = try db.reader.read { try UWBSample.fetchAll($0) }
    #expect(samples.isEmpty)
}
