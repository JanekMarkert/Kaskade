import Foundation

enum GeoJSONExport {
    static func featureCollection(fixes: [Fix], segments: [Segment]) throws -> Data {
        let sortiert = fixes.sorted { $0.ts < $1.ts }
        var features: [[String: Any]] = []

        for s in segments {
            let imSegment = sortiert.filter { $0.ts >= s.startTs && $0.ts <= s.endTs }
            guard imSegment.count >= 2 else { continue }
            features.append([
                "type": "Feature",
                "geometry": [
                    "type": "LineString",
                    "coordinates": imSegment.map { [$0.lon, $0.lat] },
                ],
                "properties": [
                    "segment_id": s.id ?? -1,
                    "kind": s.kind,
                    "predicted_mode": s.predictedMode as Any,
                    "confidence": s.confidence as Any,
                    "label_mode": s.labelMode as Any,
                    // Für die Kartenfärbung: Handlabel geht vor Modellvorhersage, damit die
                    // Route schon vor Task 16 (Core-ML-Modell) farbig dargestellt wird.
                    "color_mode": (s.labelMode ?? s.predictedMode) as Any,
                    "start_ts": s.startTs,
                    "end_ts": s.endTs,
                    "timestamps": imSegment.map { $0.ts },
                    "h_acc": imSegment.map { $0.hAcc ?? -1 },
                    // Höhe fließt als Steigrate in die Klassifikation ein; ohne sie
                    // lässt sich der Export nicht außerhalb der App nachrechnen.
                    "alt": imSegment.map { $0.alt ?? 0 },
                ],
            ])
        }

        return try JSONSerialization.data(
            withJSONObject: ["type": "FeatureCollection", "features": features],
            options: [.prettyPrinted, .sortedKeys])
    }
}
