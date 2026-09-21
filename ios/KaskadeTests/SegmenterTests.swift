import Testing
import CoreLocation
@testable import Kaskade

private func fix(_ ts: Double, _ lat: Double, _ lon: Double) -> Fix {
    Fix(id: nil, ts: ts, lat: lat, lon: lon, alt: nil, hAcc: 5, vAcc: nil,
        speed: nil, speedAcc: nil, course: nil, courseAcc: nil, sessionId: "s")
}

@Test func erkenntStoppUndFahrtAlsGetrennteSegmente() {
    var fixes: [Fix] = []
    for i in 0..<300 { fixes.append(fix(Double(i), 52.5450, 13.3550)) }
    for i in 300..<600 {
        fixes.append(fix(Double(i), 52.5450 + Double(i - 300) * 0.000009, 13.3550))
    }

    let segmente = Segmenter.segment(fixes: fixes,
                                     minStopDuration: 180, maxStopRadius: 50)
    #expect(segmente.count == 2)
    #expect(segmente[0].kind == "stop")
    #expect(segmente[1].kind == "move")
    #expect(segmente[0].endTs <= segmente[1].startTs)
}

@Test func kurzeAmpelpauseErzeugtKeinenEigenenStopp() {
    var fixes: [Fix] = []
    for i in 0..<200 {
        fixes.append(fix(Double(i), 52.5450 + Double(i) * 0.000009, 13.3550))
    }
    for i in 200..<240 { fixes.append(fix(Double(i), 52.5468, 13.3550)) }
    for i in 240..<440 {
        fixes.append(fix(Double(i), 52.5468 + Double(i - 240) * 0.000009, 13.3550))
    }

    let segmente = Segmenter.segment(fixes: fixes,
                                     minStopDuration: 180, maxStopRadius: 50)
    #expect(segmente.count == 1)
    #expect(segmente[0].kind == "move")
}

/// Realdaten kommen nicht im Sekundentakt: CoreLocation liefert Fixes mit
/// Abständen um 1 s, die Zeitstempel sind Fließkommazahlen. Der Feldtest vom
/// 20.09. (3324 Fixes, 56 min, knapp die Hälfte im Stand) ergab trotzdem ein
/// einziges move-Segment -- deshalb dieser Test mit unregelmäßigen Abständen.
@Test func erkenntStoppAuchBeiUnregelmaessigenZeitstempeln() {
    var fixes: [Fix] = []
    var ts = 0.0
    for i in 0..<300 {
        ts += 0.97 + Double(i % 7) * 0.01
        fixes.append(fix(ts, 52.5450, 13.3550))
    }
    for i in 0..<300 {
        ts += 1.03 - Double(i % 5) * 0.01
        fixes.append(fix(ts, 52.5450 + Double(i) * 0.000009, 13.3550))
    }

    let segmente = Segmenter.segment(fixes: fixes,
                                     minStopDuration: 180, maxStopRadius: 50)
    #expect(segmente.count == 2)
    #expect(segmente[0].kind == "stop")
    #expect(segmente[1].kind == "move")
}
