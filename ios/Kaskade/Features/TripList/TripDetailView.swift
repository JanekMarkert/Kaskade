import GRDB
import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    private let database = AppDatabase.shared

    @State private var segmente: [Segment] = []
    @State private var fixes: [Fix] = []
    @State private var geoJSON: Data?
    @State private var fehler: String?
    @State private var exportURLs: [URL] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let geoJSON {
                    TrackMapView(geoJSON: geoJSON)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(segmente, id: \.startTs) { segment in
                        HStack {
                            Circle().fill(ModeColors.color(for: segment.labelMode ?? segment.predictedMode))
                                .frame(width: 10, height: 10)
                            Text(segment.labelMode ?? segment.predictedMode ?? segment.kind)
                            Spacer()
                            Text("\(Int(segment.endTs - segment.startTs)) s")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                if let fehler {
                    Text(fehler).foregroundStyle(.red).padding(.horizontal)
                }

                if !exportURLs.isEmpty {
                    ShareLink(items: exportURLs) {
                        Label("Trip exportieren", systemImage: "square.and.arrow.up")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(Date(timeIntervalSince1970: trip.startTs).formatted(date: .abbreviated, time: .shortened))
        .onAppear { laden() }
    }

    private func laden() {
        guard let id = trip.id else { return }
        do {
            let gespeicherteSegmente = try database.reader.read { db in
                try Segment.filter(Column("trip_id") == id).order(Column("start_ts")).fetchAll(db)
            }
            let sessionId = gespeicherteSegmente.first?.sessionId
            fixes = sessionId.map { sid in
                (try? database.reader.read { db in
                    try Fix.filter(Column("session_id") == sid).fetchAll(db)
                }) ?? []
            } ?? []
            let events = sessionId.map { sid in
                (try? database.reader.read { db in
                    try LabelEvent.filter(Column("session_id") == sid).fetchAll(db)
                }) ?? []
            } ?? []
            // Segmente live aus den Fixes neu berechnen statt die
            // gespeicherten Segment-Zeilen zu übernehmen -- sonst zeigt die
            // App nach einem Segmenter-Fix weiter die alte, mit dem
            // fehlerhaften Algorithmus erzeugte Segmentierung.
            segmente = TripBuilder.build(fixes: fixes, events: events).1
            geoJSON = try GeoJSONExport.featureCollection(fixes: fixes, segments: segmente)

            let activities = sessionId.map { sid in
                (try? database.reader.read { db in
                    try ActivitySample.filter(Column("session_id") == sid).fetchAll(db)
                }) ?? []
            } ?? []
            exportURLs = schreibeExportDateien(geoJSON: geoJSON!, activities: activities)
        } catch {
            fehler = "Trip konnte nicht geladen werden."
        }
    }

    private func schreibeExportDateien(geoJSON: Data, activities: [ActivitySample]) -> [URL] {
        let stempel = Int(trip.startTs)
        return [
            ExportStore.save(geoJSON, name: "trip_\(stempel).geojson"),
            ExportStore.save(ActivityCSV.build(samples: activities), name: "trip_\(stempel)_activity.csv"),
        ]
    }

}
