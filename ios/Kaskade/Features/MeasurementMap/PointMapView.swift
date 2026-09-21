import CoreLocation
import MapLibre
import SwiftUI

/// Zeigt Punkte (z. B. Messorte) auf einer OSM-basierten Karte — eigene,
/// schlanke Komponente statt `TrackMapView` zu erweitern, das fest auf
/// Linien-Tracks mit `color_mode` ausgelegt ist.
struct PointMapView: UIViewRepresentable {
    let geoJSON: Data
    let mittelpunkt: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MLNMapView {
        let karte = MLNMapView(frame: .zero)
        karte.styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        karte.delegate = context.coordinator
        return karte
    }

    func updateUIView(_ karte: MLNMapView, context: Context) {
        guard context.coordinator.geoJSON != geoJSON else { return }
        context.coordinator.geoJSON = geoJSON
        if let style = karte.style { context.coordinator.zeichne(auf: style, karte: karte) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(geoJSON: geoJSON, mittelpunkt: mittelpunkt) }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var geoJSON: Data
        let mittelpunkt: CLLocationCoordinate2D?
        init(geoJSON: Data, mittelpunkt: CLLocationCoordinate2D?) {
            self.geoJSON = geoJSON
            self.mittelpunkt = mittelpunkt
        }

        func mapView(_ karte: MLNMapView, didFinishLoading style: MLNStyle) {
            karte.setCenter(mittelpunkt ?? berlinMitte, zoomLevel: mittelpunkt != nil ? 14 : berlinZoom, animated: false)
            zeichne(auf: style, karte: karte)
        }

        func zeichne(auf style: MLNStyle, karte: MLNMapView) {
            guard let shape = try? MLNShape(data: geoJSON, encoding: String.Encoding.utf8.rawValue) else { return }

            if let alteSchicht = style.layer(withIdentifier: "messorte-punkte") {
                style.removeLayer(alteSchicht)
            }
            if let alteQuelle = style.source(withIdentifier: "messorte") {
                style.removeSource(alteQuelle)
            }

            let quelle = MLNShapeSource(identifier: "messorte", shape: shape, options: nil)
            style.addSource(quelle)

            let punkte = MLNCircleStyleLayer(identifier: "messorte-punkte", source: quelle)
            punkte.circleRadius = NSExpression(forConstantValue: 8)
            punkte.circleColor = NSExpression(forConstantValue: UIColor(hex: "#e63946"))
            punkte.circleStrokeWidth = NSExpression(forConstantValue: 2)
            punkte.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
            style.addLayer(punkte)
        }
    }
}
