import Foundation

enum DepthCSV {
    static func build(samples: [DepthSample]) -> String {
        var zeilen = ["ts,true_distance,depth_m,confidence,lighting"]
        for s in samples {
            zeilen.append("\(s.ts),\(s.trueDistance),\(s.depthM),\(s.confidence),\(s.lighting)")
        }
        return zeilen.joined(separator: "\n")
    }
}
