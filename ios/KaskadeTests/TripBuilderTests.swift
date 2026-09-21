import Testing
@testable import Kaskade

private func fix(_ ts: Double, _ lat: Double, _ lon: Double, session: String = "s") -> Fix {
    Fix(id: nil, ts: ts, lat: lat, lon: lon, alt: nil, hAcc: 5, vAcc: nil,
        speed: nil, speedAcc: nil, course: nil, courseAcc: nil, sessionId: session)
}

private func ereignis(_ ts: Double, _ mode: String, session: String = "s") -> LabelEvent {
    LabelEvent(id: nil, ts: ts, mode: mode, sessionId: session)
}

@Test func buildErzeugtTripUndBeschrifteteSegmente() {
    var fixes: [Fix] = []
    for i in 0..<300 { fixes.append(fix(Double(i), 52.5450, 13.3550)) }
    for i in 300..<600 {
        fixes.append(fix(Double(i), 52.5450 + Double(i - 300) * 0.000009, 13.3550))
    }
    let events = [ereignis(0, "foot")]

    let (trip, segmente) = TripBuilder.build(fixes: fixes, events: events)

    #expect(trip.startTs == 0)
    #expect(trip.endTs == 599)
    #expect(segmente.count == 2)
    #expect(segmente.allSatisfy { $0.labelMode == "foot" })
}

@Test func persistSchreibtTripUndSegmenteMitTripId() throws {
    let db = try AppDatabase.makeInMemory()
    var fixes: [Fix] = []
    for i in 0..<300 { fixes.append(fix(Double(i), 52.5450, 13.3550)) }
    for i in 300..<600 {
        fixes.append(fix(Double(i), 52.5450 + Double(i - 300) * 0.000009, 13.3550))
    }
    try db.writer.write { db in for var f in fixes { try f.insert(db) } }
    let events = [ereignis(0, "foot")]

    let trip = try TripBuilder.persist(fixes: fixes, events: events, in: db)

    #expect(trip.id != nil)
    let segmente = try db.reader.read { try Segment.fetchAll($0) }
    #expect(segmente.count == 2)
    #expect(segmente.allSatisfy { $0.tripId == trip.id })
}
