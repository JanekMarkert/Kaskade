import CoreLocation
import SwiftUI

private let zielAnzahl = 30
private let beleuchtungen = ["tag", "nacht"]

struct DepthLabView: View {
    @StateObject private var recorder = DepthRecorder()
    @State private var solldistanzText = "1.0"
    @State private var beleuchtung = "tag"
    @State private var exportURL: URL?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var distanzFokussiert: Bool
    @State private var standort = EinmaligerStandort()
    @State private var messStempel = 0

    var body: some View {
        NavigationStack {
            inhalt
                .navigationTitle("LiDAR")
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
            if !DepthProbe.istVerfuegbar {
                Text("LiDAR auf diesem Gerät nicht verfügbar")
                    .foregroundStyle(.red)
            } else {
                ZStack {
                    DepthCameraPreview(session: recorder.session)
                    Crosshair()
                    if let tiefe = recorder.liveDepth {
                        Text(String(format: "%.3f m", tiefe))
                            .font(.headline.monospacedDigit())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .offset(y: 36)
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear { recorder.startPreview() }
                .onDisappear { recorder.stopPreview() }
            }

            TextField("Solldistanz in Metern", text: $solldistanzText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .disabled(recorder.isRunning)
                .focused($distanzFokussiert)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Fertig") { distanzFokussiert = false }
                    }
                }

            Picker("Beleuchtung", selection: $beleuchtung) {
                ForEach(beleuchtungen, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .disabled(recorder.isRunning)

            Text("\(recorder.samples.count) / \(zielAnzahl) Messungen")
                .font(.title2)

            Button(recorder.isRunning ? "Stopp" : "Start") {
                if recorder.isRunning {
                    recorder.stop()
                    exportURL = schreibeCSV()
                } else if let soll = solldistanzText.alsDezimalzahl {
                    exportURL = nil
                    messStempel = Int(Date().timeIntervalSince1970)
                    // Der Standort-Fix kann ein paar Sekunden dauern — wird
                    // geschrieben, sobald er ankommt, unabhängig davon, ob
                    // die (kurze) Messung dann schon gestoppt wurde.
                    let stempel = messStempel
                    let licht = beleuchtung
                    standort.hole { koordinate in
                        guard let koordinate else { return }
                        let name = "m4_\(licht)_\(stempel).csv"
                        ExportStore.save(MeasurementLocationGeoJSON.punkt(koordinate: koordinate, name: name),
                                          name: "m4_\(licht)_\(stempel)_ort.geojson")
                    }
                    recorder.start(trueDistance: soll, lighting: beleuchtung)
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(recorder.isRunning ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .disabled(!DepthProbe.istVerfuegbar)
            .accessibilityIdentifier("start-button")

            if let url = exportURL {
                ShareLink(item: url) {
                    Label("CSV exportieren", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
        .onChange(of: recorder.samples.count) { _, anzahl in
            if anzahl >= zielAnzahl, recorder.isRunning {
                recorder.stop()
                exportURL = schreibeCSV()
            }
        }
    }

    private func schreibeCSV() -> URL? {
        guard !recorder.samples.isEmpty else { return nil }
        let csv = DepthCSV.build(samples: recorder.samples)
        return ExportStore.save(csv, name: "m4_\(beleuchtung)_\(messStempel).csv")
    }
}

private struct Crosshair: View {
    var body: some View {
        ZStack {
            Rectangle().frame(width: 2, height: 22)
            Rectangle().frame(width: 22, height: 2)
        }
        .foregroundStyle(.yellow)
        .shadow(radius: 1)
    }
}
