import Testing
import Foundation
@testable import Kaskade

@Test func exportiertSegmentAlsLineStringMitParallelenArrays() throws {
    let fixes = [
        Fix(id: 1, ts: 100, lat: 52.54, lon: 13.35, alt: 30, hAcc: 5, vAcc: 3,
            speed: 1.2, speedAcc: 0.4, course: 90, courseAcc: 10, sessionId: "s"),
        Fix(id: 2, ts: 101, lat: 52.541, lon: 13.351, alt: 30, hAcc: 8, vAcc: 3,
            speed: 1.3, speedAcc: 0.4, course: 91, courseAcc: 10, sessionId: "s"),
    ]
    let segmente = [
        Segment(id: 7, startTs: 100, endTs: 101, kind: "move",
                predictedMode: "foot", confidence: 0.91, labelMode: "foot",
                tripId: nil, sessionId: "s")
    ]
    let daten = try GeoJSONExport.featureCollection(fixes: fixes, segments: segmente)
    let json = try JSONSerialization.jsonObject(with: daten) as! [String: Any]

    #expect(json["type"] as? String == "FeatureCollection")
    let features = json["features"] as! [[String: Any]]
    #expect(features.count == 1)

    let geometrie = features[0]["geometry"] as! [String: Any]
    #expect(geometrie["type"] as? String == "LineString")
    let koordinaten = geometrie["coordinates"] as! [[Double]]
    #expect(koordinaten.count == 2)
    #expect(abs(koordinaten[0][0] - 13.35) < 1e-9)   // lon zuerst
    #expect(abs(koordinaten[0][1] - 52.54) < 1e-9)

    let props = features[0]["properties"] as! [String: Any]
    #expect(props["predicted_mode"] as? String == "foot")
    #expect((props["timestamps"] as! [Double]).count == 2)
    #expect((props["h_acc"] as! [Double]).count == 2)
    #expect((props["alt"] as! [Double]).count == 2)
}
