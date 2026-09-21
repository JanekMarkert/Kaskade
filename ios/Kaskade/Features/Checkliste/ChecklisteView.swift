import SwiftUI

// Aus den Messprotokollen data/messprotokolle/m1.md, m3.md, m4.md.
private let m1Punkte = ["p1", "p2", "p3"]
private let m1SollSessions = 3
private let m3Distanzen: [Double] = [0.5, 1, 2, 3, 5, 7, 9]
private let m4Distanzen: [Double] = [0.3, 0.5, 1, 2, 3, 4, 5]

struct ChecklisteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var m1Zaehler: [String: Int] = [:]
    @State private var m3Erledigt: Set<String> = []
    @State private var m4Erledigt: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                Section("M1 — GNSS-Genauigkeit (3 Sessions je Punkt)") {
                    ForEach(m1Punkte, id: \.self) { punkt in
                        HStack {
                            Text(punkt.uppercased())
                            Spacer()
                            let anzahl = m1Zaehler[punkt] ?? 0
                            Text("\(anzahl) / \(m1SollSessions)")
                                .foregroundStyle(anzahl >= m1SollSessions ? .green : .secondary)
                            Image(systemName: anzahl >= m1SollSessions ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(anzahl >= m1SollSessions ? .green : .secondary)
                        }
                    }
                }

                Section("M3 — UWB / BLE (Distanz × Sicht)") {
                    ForEach(m3Distanzen, id: \.self) { distanz in
                        HStack {
                            Text(distanzText(distanz))
                            Spacer()
                            zelle("LOS", erledigt: m3Erledigt.contains(schluessel(distanz, "los")))
                            zelle("NLOS", erledigt: m3Erledigt.contains(schluessel(distanz, "nlos")))
                        }
                    }
                }

                Section("M4 — LiDAR (Distanz × Licht)") {
                    ForEach(m4Distanzen, id: \.self) { distanz in
                        HStack {
                            Text(distanzText(distanz))
                            Spacer()
                            zelle("Tag", erledigt: m4Erledigt.contains(schluessel(distanz, "tag")))
                            zelle("Nacht", erledigt: m4Erledigt.contains(schluessel(distanz, "nacht")))
                        }
                    }
                }
            }
            .navigationTitle("Checkliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("done-button")
                }
            }
            .onAppear { auswerten() }
        }
    }

    private func zelle(_ titel: String, erledigt: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: erledigt ? "checkmark.circle.fill" : "circle")
            Text(titel)
        }
        .font(.caption)
        .foregroundStyle(erledigt ? .green : .secondary)
        .frame(width: 62, alignment: .leading)
    }

    private func distanzText(_ meter: Double) -> String {
        meter.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(meter)) m" : String(format: "%.1f m", meter)
    }

    private func schluessel(_ meter: Double, _ bedingung: String) -> String {
        "\(meter)|\(bedingung)"
    }

    private func auswerten() {
        var m1 = [String: Int]()
        var m3 = Set<String>()
        var m4 = Set<String>()

        for url in ExportStore.alle() {
            let name = url.lastPathComponent
            if name.hasPrefix("m1-"), name.hasSuffix(".csv") {
                if let punkt = name.dropFirst(3).split(separator: "-").first.map(String.init) {
                    m1[punkt, default: 0] += 1
                }
            } else if name.hasPrefix("m3_"), name.hasSuffix(".csv") {
                guard let zeile = CSVErsteZeile.lesen(url),
                      let soll = zeile["true_distance"].flatMap(Double.init),
                      let los = zeile["los"],
                      let passend = m3Distanzen.first(where: { abs($0 - soll) < 0.05 })
                else { continue }
                m3.insert(schluessel(passend, los == "true" ? "los" : "nlos"))
            } else if name.hasPrefix("m4_"), name.hasSuffix(".csv") {
                guard let zeile = CSVErsteZeile.lesen(url),
                      let soll = zeile["true_distance"].flatMap(Double.init),
                      let licht = zeile["lighting"],
                      let passend = m4Distanzen.first(where: { abs($0 - soll) < 0.05 })
                else { continue }
                m4.insert(schluessel(passend, licht))
            }
        }

        m1Zaehler = m1
        m3Erledigt = m3
        m4Erledigt = m4
    }
}
