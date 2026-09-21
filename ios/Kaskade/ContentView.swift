import SwiftUI
import GRDB

struct ContentView: View {
    private let database = AppDatabase.shared
    private let leeresGeoJSON = (try? GeoJSONExport.featureCollection(fixes: [], segments: []))
        ?? Data("{\"type\":\"FeatureCollection\",\"features\":[]}".utf8)

    @State private var trackingService: TrackingService?
    @State private var isRecording = false
    @State private var sessionId = ""
    @State private var letzteSessionId: String?
    @State private var geoJSON: Data?
    @State private var zeigeM1 = false
    @State private var zeigeProximityLab = false
    @State private var liveTimer: Timer?
    @State private var aufnahmeStart: Date?
    @State private var anzahlFixes = 0
    @State private var zeigeBerechtigungsFehler = false
    @State private var zeigeDepthLab = false
    @State private var zeigeExporte = false
    @State private var zeigeAufzeichnung = false
    @State private var zeigeMessorte = false
    @State private var zeigeCheckliste = false

    var body: some View {
        hubAnsicht
            .sheet(isPresented: $zeigeM1) {
                M1MeasurementView()
            }
            .sheet(isPresented: $zeigeProximityLab) {
                ProximityLabView()
            }
            .sheet(isPresented: $zeigeDepthLab) {
                DepthLabView()
            }
            .sheet(isPresented: $zeigeExporte) {
                ExportListView()
            }
            .sheet(isPresented: $zeigeMessorte) {
                MeasurementMapView()
            }
            .sheet(isPresented: $zeigeCheckliste) {
                ChecklisteView()
            }
            .sheet(isPresented: $zeigeAufzeichnung) {
                RecordingView(database: database, leeresGeoJSON: leeresGeoJSON,
                              isRecording: $isRecording, geoJSON: $geoJSON, sessionId: $sessionId,
                              anzahlFixes: $anzahlFixes, aufnahmeStart: $aufnahmeStart,
                              toggleRecording: toggleRecording)
            }
            .alert("Standortzugriff fehlt", isPresented: $zeigeBerechtigungsFehler) {
                Button("OK") {}
            } message: {
                Text("Ohne Standortfreigabe kann nichts aufgezeichnet werden. Bitte in den Einstellungen erlauben (Immer erlauben).")
            }
            .onAppear { neuLaden(session: letzteSessionId) }
    }

    private var hubAnsicht: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Kaskade").font(.largeTitle.bold())
                Text("GNSS · BLE · UWB · LiDAR").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                grossesWerkzeug("location.fill", "GPS",
                                erklaerung: isRecording ? "läuft…" : "Route & Verkehrsmittel erkennen",
                                id: "gps-button", farbe: .blue) { zeigeAufzeichnung = true }
                grossesWerkzeug("ruler", "GNSS-Genauigkeit", erklaerung: "Positionsfehler an 3 Referenzpunkten",
                                id: "m1-button", farbe: .indigo) { zeigeM1 = true }
                grossesWerkzeug("dot.radiowaves.left.and.right", "UWB", erklaerung: "Distanz per Funk zum 2. Gerät",
                                id: "uwb-button", farbe: .teal) { zeigeProximityLab = true }
                grossesWerkzeug("cube.transparent", "LiDAR", erklaerung: "Tiefenmessung gegen Maßband",
                                id: "lidar-button", farbe: .purple) { zeigeDepthLab = true }
                grossesWerkzeug("tray.full", "Exporte", erklaerung: "Alle exportierten Dateien",
                                id: "export-button", farbe: .orange) { zeigeExporte = true }
                grossesWerkzeug("mappin.and.ellipse", "Messorte", erklaerung: "Wo gemessen wurde, auf der Karte",
                                id: "karte-button", farbe: .green) { zeigeMessorte = true }
                grossesWerkzeug("checklist", "Checkliste", erklaerung: "Was aus dem Messplan noch fehlt",
                                id: "checkliste-button", farbe: .pink) { zeigeCheckliste = true }
            }
            .padding(.horizontal)

            Spacer()

            Text("Carl Janek Markert (105906) · Paul Tschätsch (107359)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
        }
    }

    private func grossesWerkzeug(_ symbol: String, _ titel: String, erklaerung: String,
                                  id: String, farbe: Color, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 30))
                Text(titel).font(.headline)
                Text(erklaerung)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .opacity(0.85)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 130)
            .foregroundStyle(.white)
            .background(farbe.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityIdentifier(id)
    }

    private func toggleRecording() {
        if isRecording {
            trackingService?.stop()
            isRecording = false
            liveTimer?.invalidate()
            liveTimer = nil
            letzteSessionId = sessionId
            neuLaden(session: sessionId)
            tripAusSessionBauen(sessionId)
        } else {
            sessionId = UUID().uuidString
            anzahlFixes = 0
            aufnahmeStart = Date()
            let service = TrackingService(database: database)
            service.onAuthorizationDenied = { zeigeBerechtigungsFehler = true }
            service.start(sessionId: sessionId)
            trackingService = service
            isRecording = true
            liveTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                neuLaden(session: sessionId)
            }
        }
    }

    private func tripAusSessionBauen(_ session: String) {
        do {
            let fixes = try database.reader.read { db in
                try Fix.filter(Column("session_id") == session).fetchAll(db)
            }
            guard fixes.count >= 2 else { return }
            let events = try database.reader.read { db in
                try LabelEvent.filter(Column("session_id") == session).fetchAll(db)
            }
            _ = try TripBuilder.persist(fixes: fixes, events: events, in: database)
        } catch {
            // Trip wird beim nächsten Öffnen der Trip-Liste einfach fehlen.
        }
    }

    private func neuLaden(session: String?) {
        guard let session else { return }
        do {
            let fixes = try database.reader.read { db in
                try Fix.filter(Column("session_id") == session).fetchAll(db)
            }
            anzahlFixes = fixes.count
            let segmente = Segmenter.segment(fixes: fixes)
            geoJSON = try GeoJSONExport.featureCollection(fixes: fixes, segments: segmente)
        } catch {
            // Kartenansicht bleibt beim vorherigen Stand.
        }
    }
}

#Preview {
    ContentView()
}
