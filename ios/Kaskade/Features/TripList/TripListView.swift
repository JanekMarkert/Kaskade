import GRDB
import SwiftUI

struct TripListView: View {
    private let database = AppDatabase.shared
    @State private var trips: [Trip] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(trips, id: \.id) { trip in
            NavigationLink {
                TripDetailView(trip: trip)
            } label: {
                TripRow(trip: trip, database: database)
            }
        }
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") { dismiss() }
                    .accessibilityIdentifier("trips-done-button")
            }
        }
        .overlay {
            if trips.isEmpty {
                ContentUnavailableView("Noch keine Trips",
                                       systemImage: "map",
                                       description: Text("Eine abgeschlossene Aufzeichnung erscheint hier."))
            }
        }
        .onAppear { laden() }
    }

    private func laden() {
        trips = (try? database.reader.read { db in
            try Trip.order(Column("start_ts").desc).fetchAll(db)
        }) ?? []
    }
}

private struct TripRow: View {
    let trip: Trip
    let database: AppDatabase
    @State private var modi: [String] = []

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Date(timeIntervalSince1970: trip.startTs), style: .date)
                Text(dauerText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(modi, id: \.self) { modus in
                    Circle().fill(ModeColors.color(for: modus)).frame(width: 10, height: 10)
                }
            }
        }
        .onAppear { modiLaden() }
    }

    private var dauerText: String {
        let minuten = Int((trip.endTs - trip.startTs) / 60)
        return "\(minuten) Min"
    }

    private func modiLaden() {
        guard let id = trip.id else { return }
        let segmente = (try? database.reader.read { db in
            try Segment.filter(Column("trip_id") == id).fetchAll(db)
        }) ?? []
        modi = Array(Set(segmente.compactMap { $0.labelMode ?? $0.predictedMode })).sorted()
    }
}
