import ARKit
import Foundation

@MainActor
final class DepthRecorder: NSObject, ARSessionDelegate, ObservableObject {
    let session = ARSession()
    @Published private(set) var samples: [DepthSample] = []
    @Published private(set) var isRunning = false
    @Published private(set) var liveDepth: Double?

    private var sollDistanz: Double = 0
    private var beleuchtung = "tag"

    override init() {
        super.init()
        session.delegate = self
    }

    /// Läuft, sobald das LiDAR-Sheet sichtbar ist — unabhängig von einer laufenden
    /// Aufzeichnung, damit man vor „Start" schon zielen und den Live-Wert sehen kann.
    func startPreview() {
        guard DepthProbe.istVerfuegbar else { return }
        let konfiguration = ARWorldTrackingConfiguration()
        konfiguration.frameSemantics = .sceneDepth
        session.run(konfiguration)
    }

    func stopPreview() {
        session.pause()
    }

    func start(trueDistance: Double, lighting: String) {
        guard DepthProbe.istVerfuegbar else { return }
        sollDistanz = trueDistance
        beleuchtung = lighting
        samples = []
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let tiefe = frame.sceneDepth else { return }
        guard let ergebnis = DepthProbe.centerDepth(from: tiefe) else { return }
        Task { @MainActor in
            self.liveDepth = ergebnis.depth
            self.record(depth: ergebnis.depth, confidence: ergebnis.confidence)
        }
    }

    func record(depth: Double, confidence: Int) {
        guard isRunning else { return }
        samples.append(DepthSample(id: nil, ts: Date().timeIntervalSince1970,
                                   depthM: depth, confidence: confidence,
                                   trueDistance: sollDistanz, lighting: beleuchtung))
    }
}
