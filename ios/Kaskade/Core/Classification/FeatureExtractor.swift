import Foundation

/// Spiegelbild von analysis/geolife/features.py.
/// Jede Änderung hier muss dort ebenfalls erfolgen — FeatureParityTests prüft das.
enum FeatureExtractor {
    static let erdRadius = 6_371_008.8
    static let stoppSchwelleMS = 0.5

    static let featureNames = [
        "v_median", "v_p85", "v_max", "v_std",
        "a_std", "a_p85", "kurswechselrate", "stopprate", "steigrate",
    ]

    static func features(ts: [Double], lat: [Double],
                         lon: [Double], alt: [Double]) -> [Double] {
        guard ts.count >= 2 else { return [Double](repeating: 0, count: featureNames.count) }

        var v: [Double] = []
        for i in 1..<ts.count {
            let dt = ts[i] - ts[i - 1]
            guard dt > 0 else { continue }
            v.append(abstand(lat[i - 1], lon[i - 1], lat[i], lon[i]) / dt)
        }
        guard !v.isEmpty else { return [Double](repeating: 0, count: featureNames.count) }

        var a: [Double] = []
        if v.count > 1 {
            for i in 1..<v.count {
                let dt = ts[i] - ts[i - 1]
                guard dt > 0 else { continue }
                a.append((v[i] - v[i - 1]) / dt)
            }
        }
        if a.isEmpty { a = [0.0] }

        var kurse: [Double] = []
        for i in 1..<ts.count { kurse.append(kurs(lat[i - 1], lon[i - 1], lat[i], lon[i])) }
        var kurswechselrate = 0.0
        if kurse.count > 1 {
            var summe = 0.0
            for i in 1..<kurse.count {
                let d = abs(kurse[i] - kurse[i - 1])
                summe += min(d, 360.0 - d)
            }
            kurswechselrate = summe / (ts[ts.count - 1] - ts[0])
        }

        var steigrate = 0.0
        if alt.count > 1 {
            var summe = 0.0
            for i in 1..<alt.count { summe += abs(alt[i] - alt[i - 1]) }
            steigrate = summe / (ts[ts.count - 1] - ts[0])
        }

        let stopprate = Double(v.filter { $0 < stoppSchwelleMS }.count) / Double(v.count)

        return [
            median(v), quantil(v, 0.85), v.max()!, stdabw(v),
            stdabw(a), quantil(a.map { abs($0) }, 0.85),
            kurswechselrate, stopprate, steigrate,
        ]
    }

    static func abstand(_ lat1: Double, _ lon1: Double,
                        _ lat2: Double, _ lon2: Double) -> Double {
        let dlat = (lat2 - lat1) * .pi / 180
        let dlon = (lon2 - lon1) * .pi / 180
        let mittelLat = (lat1 + lat2) / 2 * .pi / 180
        let nord = dlat * erdRadius
        let ost = dlon * erdRadius * cos(mittelLat)
        return (nord * nord + ost * ost).squareRoot()
    }

    static func kurs(_ lat1: Double, _ lon1: Double,
                     _ lat2: Double, _ lon2: Double) -> Double {
        let dlat = (lat2 - lat1) * .pi / 180
        let dlon = (lon2 - lon1) * .pi / 180
        let mittelLat = (lat1 + lat2) / 2 * .pi / 180
        let grad = atan2(dlon * cos(mittelLat), dlat) * 180 / .pi
        return grad.truncatingRemainder(dividingBy: 360) < 0
            ? grad.truncatingRemainder(dividingBy: 360) + 360
            : grad.truncatingRemainder(dividingBy: 360)
    }

    /// numpy.quantile mit der Standardmethode "linear".
    static func quantil(_ werte: [Double], _ q: Double) -> Double {
        let s = werte.sorted()
        guard s.count > 1 else { return s.first ?? 0 }
        let pos = q * Double(s.count - 1)
        let unten = Int(pos.rounded(.down))
        let oben = min(unten + 1, s.count - 1)
        let anteil = pos - Double(unten)
        return s[unten] * (1 - anteil) + s[oben] * anteil
    }

    static func median(_ werte: [Double]) -> Double { quantil(werte, 0.5) }

    /// numpy.std, also Division durch n, nicht durch n-1.
    static func stdabw(_ werte: [Double]) -> Double {
        guard !werte.isEmpty else { return 0 }
        let m = werte.reduce(0, +) / Double(werte.count)
        let varianz = werte.map { ($0 - m) * ($0 - m) }.reduce(0, +) / Double(werte.count)
        return varianz.squareRoot()
    }
}
