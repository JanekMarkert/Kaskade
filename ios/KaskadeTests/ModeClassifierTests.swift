import Testing
@testable import Kaskade

@Test func klassifiziertMitGueltigerKlasseUndNormierterKonfidenz() throws {
    // Leichtes Rauschen statt exakt konstanter Geschwindigkeit — sonst
    // erkennt das Modell das perfekt gleichmäßige Muster als "train"
    // (physikalisch nachvollziehbar, aber nicht das, was dieser Test
    // prüfen soll: nur dass Klasse und Konfidenz gültige Werte sind).
    var fixes: [Fix] = []
    for i in 0..<60 {
        let rauschen = Double.random(in: -0.000001...0.000001)
        fixes.append(Fix(id: nil, ts: Double(i),
                         lat: 52.5450 + Double(i) * 0.0000117 + rauschen,
                         lon: 13.3550 + rauschen, alt: 34, hAcc: 5, vAcc: 3,
                         speed: 1.3, speedAcc: 0.5, course: 0, courseAcc: 10,
                         sessionId: "s"))
    }
    let ergebnis = try #require(ModeClassifier.classify(fixes: fixes))
    #expect(["foot", "bike", "car", "train", "plane"].contains(ergebnis.mode))
    #expect(ergebnis.confidence > 0.0 && ergebnis.confidence <= 1.0)
}

@Test func gibtNilBeiZuWenigenFixes() {
    let fixes = [Fix(id: nil, ts: 0, lat: 52.545, lon: 13.355, alt: nil,
                     hAcc: 5, vAcc: nil, speed: nil, speedAcc: nil,
                     course: nil, courseAcc: nil, sessionId: "s")]
    #expect(ModeClassifier.classify(fixes: fixes) == nil)
}
