import Foundation

/// Verbindet Segmenter, LabelAssignment und die Trip-Tabelle: aus den Fixes
/// und Label-Ereignissen einer Aufzeichnung wird ein persistierter Trip mit
/// beschrifteten Segmenten.
enum TripBuilder {
    static func build(fixes: [Fix], events: [LabelEvent]) -> (Trip, [Segment]) {
        let sortiert = fixes.sorted { $0.ts < $1.ts }
        let segmente = Segmenter.segment(fixes: sortiert)
        let vorhergesagt = ModeClassifier.annotate(segments: segmente, with: sortiert)
        let beschriftet = LabelAssignment.apply(events: events, to: vorhergesagt)
        let trip = Trip(id: nil,
                        startTs: sortiert.first?.ts ?? 0,
                        endTs: sortiert.last?.ts ?? 0,
                        title: nil)
        return (trip, beschriftet)
    }

    static func persist(fixes: [Fix], events: [LabelEvent], in database: AppDatabase) throws -> Trip {
        let (roherTrip, segmente) = build(fixes: fixes, events: events)
        var trip = roherTrip
        try database.writer.write { db in
            try trip.insert(db)
            for var segment in segmente {
                segment.tripId = trip.id
                try segment.insert(db)
            }
        }
        return trip
    }
}
