import SwiftUI
import MapLibre
import os

struct TrackMapView: UIViewRepresentable {
    let geoJSON: Data

    func makeUIView(context: Context) -> MLNMapView {
        let karte = MLNMapView(frame: .zero)
        karte.styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        karte.delegate = context.coordinator
        return karte
    }

    func updateUIView(_ karte: MLNMapView, context: Context) {
        guard context.coordinator.geoJSON != geoJSON else { return }
        context.coordinator.geoJSON = geoJSON
        if let style = karte.style { context.coordinator.zeichne(auf: style) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(geoJSON: geoJSON) }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        private static let log = Logger(subsystem: "de.bht.traveltracker", category: "TrackMapView")

        var geoJSON: Data
        init(geoJSON: Data) { self.geoJSON = geoJSON }

        func mapView(_ karte: MLNMapView, didFinishLoading style: MLNStyle) {
            karte.setCenter(berlinMitte, zoomLevel: berlinZoom, animated: false)
            zeichne(auf: style)
        }

        func zeichne(auf style: MLNStyle) {
            // Abweichung vom Brief: MLNShapeSource(identifier:data:options:) existiert in
            // MapLibre 6.29.0 nicht. Stattdessen wird das GeoJSON per MLNShape(data:encoding:)
            // in ein MLNShape geparst und darüber die Quelle erzeugt.
            guard let shape = try? MLNShape(data: geoJSON, encoding: String.Encoding.utf8.rawValue) else {
                Self.log.error("GeoJSON konnte nicht als MLNShape geparst werden, Karte wird nicht aktualisiert.")
                return
            }

            // Reihenfolge wichtig: MLNStyle erlaubt das Entfernen einer Source nicht, solange
            // eine Layer noch darauf verweist (wirft zur Laufzeit eine Exception). Deshalb zuerst
            // die alte Layer, dann die alte Source entfernen, bevor beide neu angelegt werden.
            // Beim allerersten Zeichnen (didFinishLoading) existiert noch nichts, daher greift
            // dieser Pfad erst ab dem zweiten Aufruf von zeichne(auf:) – z. B. wenn updateUIView
            // mit neuen Track-Daten erneut aufgerufen wird, nachdem der Stil bereits geladen ist.
            if let alteSchicht = style.layer(withIdentifier: "track-line") {
                style.removeLayer(alteSchicht)
            }
            if let alteQuelle = style.source(withIdentifier: "track") {
                style.removeSource(alteQuelle)
            }

            let quelle = MLNShapeSource(identifier: "track", shape: shape, options: nil)
            style.addSource(quelle)

            let linie = MLNLineStyleLayer(identifier: "track-line", source: quelle)
            linie.lineWidth = NSExpression(forConstantValue: 4)
            linie.lineJoin = NSExpression(forConstantValue: "round")
            // Abweichung vom Brief: Das Format `NSExpression(format: "MGL_MATCH(...)")` wirft
            // zur Laufzeit "Use of 'MGL_MATCH' as an NSExpression function is forbidden" (Absturz
            // beim Start, siehe App-Log). MapLibre 6.29.0 stellt für Match-Ausdrücke stattdessen
            // die dedizierte Fabrikmethode NSExpression(forMLNMatchingKey:in:default:) bereit.
            var zuordnung: [NSExpression: NSExpression] = [:]
            for (modus, farbe) in ModeColors.table {
                zuordnung[NSExpression(forConstantValue: modus)] =
                    NSExpression(forConstantValue: UIColor(hex: farbe))
            }
            linie.lineColor = NSExpression(
                forMLNMatchingKey: NSExpression(forKeyPath: "color_mode"),
                in: zuordnung,
                default: NSExpression(forConstantValue: UIColor(hex: "#9aa0a6")))
            style.addLayer(linie)
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var wert: UInt64 = 0
        Scanner(string: s).scanHexInt64(&wert)
        let r = CGFloat((wert & 0xFF0000) >> 16) / 255
        let g = CGFloat((wert & 0x00FF00) >> 8) / 255
        let b = CGFloat(wert & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
