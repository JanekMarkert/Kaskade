import Testing
import CoreLocation
@testable import Kaskade

@Test func schreibtEmpfangeneFixesInDieDatenbank() throws {
    let db = try AppDatabase.makeInMemory()
    let service = TrackingService(database: db)
    service.start(sessionId: "test")

    let ort = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 52.5450, longitude: 13.3550),
        altitude: 34, horizontalAccuracy: 5, verticalAccuracy: 3,
        course: 90, speed: 1.4, timestamp: Date(timeIntervalSince1970: 1_757_000_000))
    service.handle(locations: [ort])

    let fixes = try db.reader.read { try Fix.fetchAll($0) }
    #expect(fixes.count == 1)
    #expect(fixes[0].sessionId == "test")
    #expect(abs((fixes[0].speed ?? 0) - 1.4) < 1e-6)
}

@Test func verwirftFixesOhneGueltigeGenauigkeit() throws {
    let db = try AppDatabase.makeInMemory()
    let service = TrackingService(database: db)
    service.start(sessionId: "test")

    let ungueltig = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        altitude: 0, horizontalAccuracy: -1, verticalAccuracy: -1,
        course: -1, speed: -1, timestamp: Date())
    service.handle(locations: [ungueltig])

    let fixes = try db.reader.read { try Fix.fetchAll($0) }
    #expect(fixes.isEmpty)
}
