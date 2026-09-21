import Testing
import Foundation
@testable import Kaskade

private struct Fixture: Decodable {
    let ts: [Double]
    let lat: [Double]
    let lon: [Double]
    let alt: [Double]
    let features: [Double]
}

@Test func swiftFeaturesStimmenMitPythonReferenzUeberein() throws {
    let url = Bundle(for: BundleMarker.self)
        .url(forResource: "window_reference", withExtension: "json")!
    let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))

    let berechnet = FeatureExtractor.features(
        ts: fixture.ts, lat: fixture.lat, lon: fixture.lon, alt: fixture.alt)

    #expect(berechnet.count == fixture.features.count)
    for (i, (a, b)) in zip(berechnet, fixture.features).enumerated() {
        #expect(abs(a - b) < 1e-6,
                "Feature \(FeatureExtractor.featureNames[i]): Swift \(a), Python \(b)")
    }
}

@Test func featureReihenfolgeStimmtMitPythonUeberein() {
    #expect(FeatureExtractor.featureNames == [
        "v_median", "v_p85", "v_max", "v_std",
        "a_std", "a_p85", "kurswechselrate", "stopprate", "steigrate",
    ])
}

final class BundleMarker {}
