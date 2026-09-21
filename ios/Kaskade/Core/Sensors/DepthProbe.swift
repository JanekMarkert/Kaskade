import ARKit
import CoreVideo
import Foundation

enum DepthProbe {
    static var istVerfuegbar: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }

    static func centerValue(of buffer: CVPixelBuffer) -> Double? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let basis = CVPixelBufferGetBaseAddress(buffer)?
            .assumingMemoryBound(to: Float32.self) else { return nil }
        let breite = CVPixelBufferGetWidth(buffer)
        let hoehe = CVPixelBufferGetHeight(buffer)
        let zeilen = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size
        let wert = basis[(hoehe / 2) * zeilen + (breite / 2)]
        return wert.isFinite && wert > 0 ? Double(wert) : nil
    }

    static func centerDepth(from daten: ARDepthData) -> (depth: Double, confidence: Int)? {
        guard let tiefe = centerValue(of: daten.depthMap) else { return nil }
        var konfidenz = ARConfidenceLevel.high.rawValue
        if let karte = daten.confidenceMap {
            CVPixelBufferLockBaseAddress(karte, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(karte, .readOnly) }
            if let basis = CVPixelBufferGetBaseAddress(karte)?
                .assumingMemoryBound(to: UInt8.self) {
                let breite = CVPixelBufferGetWidth(karte)
                let hoehe = CVPixelBufferGetHeight(karte)
                let zeilen = CVPixelBufferGetBytesPerRow(karte)
                konfidenz = Int(basis[(hoehe / 2) * zeilen + (breite / 2)])
            }
        }
        return (tiefe, konfidenz)
    }
}
