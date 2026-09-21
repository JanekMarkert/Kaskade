import Testing
import GRDB
@testable import Kaskade

@Test func migrationLegtAlleTabellenAn() throws {
    let db = try AppDatabase.makeInMemory()
    let tabellen = try db.reader.read { db in
        try String.fetchAll(db, sql:
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
    }
    #expect(tabellen.contains("fix"))
    #expect(tabellen.contains("motion_sample"))
    #expect(tabellen.contains("activity_sample"))
    #expect(tabellen.contains("label_event"))
    #expect(tabellen.contains("beacon_sample"))
    #expect(tabellen.contains("uwb_sample"))
    #expect(tabellen.contains("depth_sample"))
    #expect(tabellen.contains("segment"))
    #expect(tabellen.contains("trip"))
}

@Test func fixLaesstSichSchreibenUndLesen() throws {
    let db = try AppDatabase.makeInMemory()
    var f = Fix(ts: 1_757_000_000, lat: 52.5450, lon: 13.3550, alt: 34.0,
                hAcc: 5.0, vAcc: 3.0, speed: 1.4, speedAcc: 0.5,
                course: 90.0, courseAcc: 10.0, sessionId: "s1")
    try db.writer.write { try f.insert($0) }
    let gelesen = try db.reader.read { try Fix.fetchAll($0) }
    #expect(gelesen.count == 1)
    #expect(abs(gelesen[0].lat - 52.5450) < 1e-9)
}
