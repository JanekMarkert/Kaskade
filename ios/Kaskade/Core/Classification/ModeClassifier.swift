import CoreML
import Foundation

enum ModeClassifier {
    // MLModel-Vorhersagen sind laut Apple threadsicher; TransportMode ist nur
    // deshalb nicht Sendable, weil der von coremltools generierte Wrapper
    // keine Sendable-Konformität deklariert.
    nonisolated(unsafe) private static let modell: TransportMode? = try? TransportMode(
        configuration: MLModelConfiguration())

    static func classify(fixes: [Fix]) -> (mode: String, confidence: Double)? {
        guard fixes.count >= 10, let modell else { return nil }
        let sortiert = fixes.sorted { $0.ts < $1.ts }
        let werte = FeatureExtractor.features(
            ts: sortiert.map(\.ts), lat: sortiert.map(\.lat),
            lon: sortiert.map(\.lon), alt: sortiert.map { $0.alt ?? 0 })

        guard let ausgabe = try? modell.prediction(
            v_median: werte[0], v_p85: werte[1], v_max: werte[2], v_std: werte[3],
            a_std: werte[4], a_p85: werte[5], kurswechselrate: werte[6],
            stopprate: werte[7], steigrate: werte[8])
        else { return nil }

        // classProbability liefert bei diesem coremltools-Export die rohen
        // Stimmen der einzelnen Bäume (Summe = n_estimators), keine
        // normierten Wahrscheinlichkeiten — deshalb hier durch die Summe
        // aller Klassen teilen.
        let klasse = ausgabe.mode
        let summe = ausgabe.classProbability.values.reduce(0, +)
        let konfidenz = summe > 0 ? (ausgabe.classProbability[klasse] ?? 0) / summe : 0
        return (klasse, konfidenz)
    }

    static func annotate(segments: [Segment], with fixes: [Fix]) -> [Segment] {
        segments.map { s in
            guard s.kind == "move" else { return s }
            let imSegment = fixes.filter { $0.ts >= s.startTs && $0.ts <= s.endTs }
            guard let e = classify(fixes: imSegment) else { return s }
            var kopie = s
            kopie.predictedMode = e.mode
            kopie.confidence = e.confidence
            return kopie
        }
    }
}
