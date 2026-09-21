import SwiftUI

private let punkte = ["p1", "p2", "p3"]

// Aus data/reference/reference_points.geojson — hier noch einmal in Worten,
// damit man im Feld nicht extra die Datei nachschlagen muss.
private let punktBeschreibung: [String: String] = [
    "p1": "BHT-Campus Wedding, Gebäudeecke — Häuserschlucht\n52,5436505° N, 13,3533855° O",
    "p2": "Rummelsburger Ufer, Gebäudeecke am Wasser — freier Himmel\n52,4999012° N, 13,476838° O",
    "p3": "Innenhof „Grüne Stadt“, Kniprodestraße — verschattet\n52,5315135° N, 13,4394625° O",
]

struct M1MeasurementView: View {
    @StateObject private var recorder = M1Recorder()
    @State private var punkt = "p1"
    @State private var session = ""
    @State private var exportURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            inhalt
                .navigationTitle("GNSS-Genauigkeit")
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
            Text("Misst 10 Minuten lang die GNSS-Position an einem festen, vorher vermessenen Referenzpunkt — zeigt, wie stark die Positionsabweichung je nach Umgebung schwankt.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Picker("Referenzpunkt", selection: $punkt) {
                ForEach(punkte, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            .disabled(recorder.isRecording)

            Text(punktBeschreibung[punkt] ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("\(recorder.fixes.count) Fixes")
                .font(.title2)

            Button(recorder.isRecording ? "Stopp" : "Start") {
                if recorder.isRecording {
                    recorder.stop()
                } else {
                    session = "m1-\(punkt)-\(Int(Date().timeIntervalSince1970))"
                    recorder.start()
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(recorder.isRecording ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("start-button")

            if let url = exportURL {
                ShareLink(item: url) {
                    Label("CSV exportieren", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding()
        .onChange(of: recorder.isRecording) { _, aufnahmeLaeuft in
            guard !aufnahmeLaeuft, !recorder.fixes.isEmpty else { return }
            exportURL = schreibeCSV()
        }
    }

    private func schreibeCSV() -> URL? {
        let csv = M1CSV.build(fixes: recorder.fixes, pointId: punkt, session: session)
        return ExportStore.save(csv, name: "\(session).csv")
    }
}
