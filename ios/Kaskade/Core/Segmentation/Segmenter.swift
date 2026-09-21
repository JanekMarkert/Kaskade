import CoreLocation
import Foundation

enum Segmenter {
    static func segment(fixes: [Fix],
                        minStopDuration: TimeInterval = 180,
                        maxStopRadius: CLLocationDistance = 50) -> [Segment] {
        let sortiert = fixes.sorted { $0.ts < $1.ts }
        guard sortiert.count >= 2 else { return [] }

        var istStopp = [Bool](repeating: false, count: sortiert.count)
        var start = 0
        for ende in 0..<sortiert.count {
            while start < ende, sortiert[ende].ts - sortiert[start + 1].ts >= minStopDuration { start += 1 }
            guard sortiert[ende].ts - sortiert[start].ts >= minStopDuration else { continue }
            if radius(sortiert[start...ende]) <= maxStopRadius {
                for i in start...ende { istStopp[i] = true }
            }
        }

        var segmente: [Segment] = []
        var laufStart = 0
        for i in 1...sortiert.count {
            let wechsel = i == sortiert.count || istStopp[i] != istStopp[laufStart]
            guard wechsel else { continue }
            segmente.append(Segment(id: nil,
                                    startTs: sortiert[laufStart].ts,
                                    endTs: sortiert[i - 1].ts,
                                    kind: istStopp[laufStart] ? "stop" : "move",
                                    predictedMode: nil, confidence: nil,
                                    labelMode: nil, tripId: nil,
                                    sessionId: sortiert[laufStart].sessionId))
            laufStart = i
        }
        return segmente
    }

    private static func radius(_ fenster: ArraySlice<Fix>) -> CLLocationDistance {
        let mittelLat = fenster.map(\.lat).reduce(0, +) / Double(fenster.count)
        let mittelLon = fenster.map(\.lon).reduce(0, +) / Double(fenster.count)
        let mitte = CLLocation(latitude: mittelLat, longitude: mittelLon)
        return fenster
            .map { CLLocation(latitude: $0.lat, longitude: $0.lon).distance(from: mitte) }
            .max() ?? 0
    }
}
