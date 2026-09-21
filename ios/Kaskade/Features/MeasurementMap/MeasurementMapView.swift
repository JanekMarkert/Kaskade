import CoreLocation
import SwiftUI

private struct Messort: Identifiable {
    let id: String
    let herkunft: String
    let koordinate: CLLocationCoordinate2D
}

struct MeasurementMapView: View {
    @State private var orte: [Messort] = []
    @State private var geoJSON: Data?
    @State private var mittelpunkt: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if orte.isEmpty {
                    ContentUnavailableView("Noch keine Messorte", systemImage: "mappin.slash",
                                           description: Text("Sobald UWB- oder LiDAR-Messungen exportiert wurden, erscheinen ihre Standorte hier."))
                } else {
                    VStack(spacing: 0) {
                        if let geoJSON {
                            PointMapView(geoJSON: geoJSON, mittelpunkt: mittelpunkt)
                                .frame(height: 240)
                        }

                        List(orte) { ort in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ort.herkunft).font(.subheadline.weight(.medium))
                                Text(String(format: "%.5f, %.5f", ort.koordinate.latitude, ort.koordinate.longitude))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Messorte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("done-button")
                }
            }
            .onAppear { laden() }
        }
    }

    private func laden() {
        let dateien = ExportStore.alle().filter { $0.lastPathComponent.hasSuffix("_ort.geojson") }
        guard !dateien.isEmpty else { return }

        var gefundeneOrte: [Messort] = []
        var features: [[String: Any]] = []
        for datei in dateien {
            guard let daten = try? Data(contentsOf: datei),
                  let objekt = try? JSONSerialization.jsonObject(with: daten) as? [String: Any],
                  let geometrie = objekt["geometry"] as? [String: Any],
                  let koordinaten = geometrie["coordinates"] as? [Double], koordinaten.count == 2
            else { continue }

            let koordinate = CLLocationCoordinate2D(latitude: koordinaten[1], longitude: koordinaten[0])
            let quellname = (objekt["properties"] as? [String: Any])?["name"] as? String ?? datei.lastPathComponent
            gefundeneOrte.append(Messort(id: datei.lastPathComponent,
                                         herkunft: ExportStore.herkunft(fürDatei: quellname),
                                         koordinate: koordinate))
            features.append(objekt)
        }
        guard !features.isEmpty else { return }

        orte = gefundeneOrte
        mittelpunkt = gefundeneOrte.first?.koordinate
        let sammlung: [String: Any] = ["type": "FeatureCollection", "features": features]
        geoJSON = try? JSONSerialization.data(withJSONObject: sammlung)
    }
}
