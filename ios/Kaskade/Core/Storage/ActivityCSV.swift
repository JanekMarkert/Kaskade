import Foundation

enum ActivityCSV {
    static func build(samples: [ActivitySample]) -> String {
        var zeilen = ["ts,cm_activity,cm_confidence"]
        for s in samples {
            zeilen.append("\(s.ts),\(s.cmActivity),\(s.cmConfidence)")
        }
        return zeilen.joined(separator: "\n")
    }
}
