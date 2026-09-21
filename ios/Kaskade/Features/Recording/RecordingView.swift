import SwiftUI

/// Eigener Bildschirm für die GPS-Aufzeichnung (wie M1/UWB/LiDAR ihre
/// eigenen Bildschirme haben) — der Zustand bleibt bewusst in `ContentView`,
/// nicht hier, damit die Aufzeichnung weiterläuft, wenn dieses Sheet
/// geschlossen wird.
struct RecordingView: View {
    let database: AppDatabase
    let leeresGeoJSON: Data
    @Binding var isRecording: Bool
    @Binding var geoJSON: Data?
    @Binding var sessionId: String
    @Binding var anzahlFixes: Int
    @Binding var aufnahmeStart: Date?
    let toggleRecording: () -> Void

    @State private var zeigeTrips = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isRecording {
                    aufzeichnungAnsicht
                } else {
                    bereitAnsicht
                }
            }
            .navigationTitle("GPS-Aufzeichnung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("done-button")
                }
            }
        }
        .sheet(isPresented: $zeigeTrips) {
            NavigationStack { TripListView() }
        }
    }

    // Eigene VStack statt ZStack-Überlagerung: „Trips ansehen" und der
    // Start-Knopf sind zwei getrennte Elemente derselben Spalte, sonst
    // landen beide am unteren Rand übereinander und werden unlesbar.
    private var bereitAnsicht: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "location.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Zeichnet die Route eines Wegs auf und erkennt automatisch das Verkehrsmittel (zu Fuß, Rad, Auto, Zug, Flug) je Abschnitt.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Button("Trips ansehen") { zeigeTrips = true }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("trips-button")
            Button("Aufzeichnung starten") { toggleRecording() }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .accessibilityIdentifier("start-button")
        }
        .padding(.bottom, 8)
    }

    private var aufzeichnungAnsicht: some View {
        ZStack(alignment: .bottom) {
            TrackMapView(geoJSON: geoJSON ?? leeresGeoJSON)
                .ignoresSafeArea()

            VStack {
                liveStatistik
                Spacer()
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                LabelBarView(database: database, sessionId: sessionId)

                Button("Aufzeichnung stoppen") { toggleRecording() }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .accessibilityIdentifier("start-button")
            }
            .padding(.bottom, 8)
        }
    }

    private var liveStatistik: some View {
        HStack {
            Label("\(anzahlFixes) Fixes", systemImage: "location.fill")
            if let start = aufnahmeStart {
                Label(dauerText(seit: start), systemImage: "clock")
            }
        }
        .font(.footnote)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private func dauerText(seit start: Date) -> String {
        let sekunden = Int(Date().timeIntervalSince(start))
        return String(format: "%02d:%02d", sekunden / 60, sekunden % 60)
    }
}
