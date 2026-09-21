import CoreLocation
import MultipeerConnectivity
import NearbyInteraction
import SwiftUI

private let rollen = ["Messgerät", "Anker"]

struct ProximityLabView: View {
    private let database = AppDatabase.shared
    @State private var rolle = "Messgerät"

    @State private var ranger: UWBRanger?
    @State private var beaconRanger: BeaconRanger?
    @State private var beaconAdvertiser: BeaconAdvertiser?
    @State private var discovery: PeerDiscovery?
    @State private var solldistanzText = "2.0"
    @State private var freieSicht = true
    @State private var laeuft = false
    @State private var anzahlMessungen = 0
    @State private var exportURL: URL?
    @State private var statusText = "Bereit"
    @FocusState private var distanzFokussiert: Bool
    @State private var standort = EinmaligerStandort()
    @State private var messStempel = 0

    private let zielAnzahl = 60
    @Environment(\.dismiss) private var dismiss

    private var fortschrittProzent: Int {
        Int((Double(anzahlMessungen) / Double(zielAnzahl) * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            inhalt
                .navigationTitle("UWB / BLE")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") { dismiss() }
                            .accessibilityIdentifier("done-button")
                    }
                }
        }
    }

    private var inhalt: some View {
        VStack(spacing: 20) {
            Text("Vergleicht, wie genau UWB (Ultrabreitband) und BLE (Bluetooth-Signalstärke) den Abstand zwischen zwei Handys schätzen. Ein Gerät ist „Anker“ (bleibt stehen), das andere „Messgerät“ (misst).")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Picker("Rolle", selection: $rolle) {
                ForEach(rollen, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .disabled(laeuft)

            if rolle == "Messgerät" {
                TextField("Solldistanz in Metern", text: $solldistanzText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .disabled(laeuft)
                    .focused($distanzFokussiert)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Fertig") { distanzFokussiert = false }
                        }
                    }

                Toggle("Freie Sicht (LOS)", isOn: $freieSicht)
                    .disabled(laeuft)

                Text("\(anzahlMessungen) / \(zielAnzahl) Messungen (UWB) — \(fortschrittProzent)%")
                    .font(.title2)
                ProgressView(value: Double(anzahlMessungen), total: Double(zielAnzahl))
            } else {
                Text("Gerät steht fest, sendet als Beacon und nimmt an der\nUWB-Kopplung teil. Kein eigener Messwert nötig.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            Button(laeuft ? "Stopp" : "Start") {
                laeuft ? stopMessung() : startMessung()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(laeuft ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("start-button")

            if !UWBRanger.istVerfuegbar {
                Text("Ultrabreitband auf diesem Gerät nicht verfügbar")
                    .foregroundStyle(.red)
            }

            if laeuft {
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let url = exportURL {
                ShareLink(item: url) {
                    Label("CSV exportieren (UWB + BLE)", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
    }

    private func startMessung() {
        statusText = "Suche Partner-Gerät…"
        messStempel = Int(Date().timeIntervalSince1970)
        // Der Standort-Fix kann ein paar Sekunden dauern — wird geschrieben,
        // sobald er ankommt, unabhängig davon, ob die Messung dann schon
        // gestoppt wurde. Sonst fehlt der Ort bei kurzen Messungen einfach.
        standort.hole { koordinate in
            guard let koordinate else { return }
            let name = "m3_\(messStempel).csv"
            ExportStore.save(MeasurementLocationGeoJSON.punkt(koordinate: koordinate, name: name),
                              name: "m3_\(messStempel)_ort.geojson")
        }
        let neuerRanger = UWBRanger(database: database)
        let eigenerToken = neuerRanger.vorbereiten()
        neuerRanger.onInvalidated = { error in
            DispatchQueue.main.async { statusText = "UWB-Fehler: \(error.localizedDescription)" }
        }

        // Nur das Messgerät sucht aktiv und lädt ein — der Anker wartet nur.
        // Sonst laden sich bei Sichtkontakt beide Seiten gleichzeitig ein und
        // MultipeerConnectivity wirft die zuerst verbundene Session raus.
        let neueDiscovery = PeerDiscovery(istInitiator: rolle == "Messgerät")
        discovery = neueDiscovery
        neueDiscovery.onStateChanged = { state in
            let text: String
            switch state {
            case .notConnected: text = "Suche Partner-Gerät…"
            case .connecting: text = "Verbinde…"
            case .connected: text = "Verbunden — tausche UWB-Token…"
            @unknown default: text = "Unbekannter Status"
            }
            DispatchQueue.main.async { statusText = text }
        }
        neueDiscovery.onConnected = {
            if let token = eigenerToken { neueDiscovery.sendToken(token) }
        }
        neueDiscovery.onTokenReceived = { token in
            neuerRanger.start(peerToken: token)
            DispatchQueue.main.async { statusText = "Token erhalten — Messung läuft…" }
        }

        if rolle == "Anker" {
            let advertiser = BeaconAdvertiser()
            advertiser.start()
            beaconAdvertiser = advertiser

            neuerRanger.setTruth(distance: 0, los: true)
            ranger = neuerRanger
            neueDiscovery.start()
            laeuft = true
            return
        }

        guard let soll = solldistanzText.alsDezimalzahl else { return }
        anzahlMessungen = 0
        exportURL = nil

        neuerRanger.setTruth(distance: soll, los: freieSicht)
        neuerRanger.onRecorded = {
            DispatchQueue.main.async {
                anzahlMessungen += 1
                if anzahlMessungen >= zielAnzahl { stopMessung() }
            }
        }
        ranger = neuerRanger

        let neuerBeaconRanger = BeaconRanger(database: database)
        neuerBeaconRanger.setTruth(distance: soll, los: freieSicht)
        beaconRanger = neuerBeaconRanger
        neuerBeaconRanger.start()

        neueDiscovery.start()
        laeuft = true
    }

    private func stopMessung() {
        ranger?.stop()
        beaconRanger?.stop()
        beaconAdvertiser?.stop()
        discovery?.stop()
        laeuft = false

        if rolle == "Messgerät", let uwb = ranger?.samples, let ble = beaconRanger?.samples,
           !(uwb.isEmpty && ble.isEmpty) {
            let csv = M3CSV.build(uwb: uwb, ble: ble)
            exportURL = ExportStore.save(csv, name: "m3_\(messStempel).csv")
        }
    }
}
