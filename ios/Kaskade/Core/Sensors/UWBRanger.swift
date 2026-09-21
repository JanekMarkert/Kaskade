import Foundation
import NearbyInteraction
import simd

final class UWBRanger: NSObject, NISessionDelegate {
    private let database: AppDatabase
    private var session: NISession?
    private var sollDistanz: Double?
    private var los = true

    static var istVerfuegbar: Bool { NISession.deviceCapabilities.supportsPreciseDistanceMeasurement }
    var onRecorded: (() -> Void)?
    /// Ohne diesen Callback bricht eine ungültige/abgelehnte NISession lautlos
    /// ab — kein Absturz, aber es kommen nie Distanzwerte an.
    var onInvalidated: ((Error) -> Void)?
    private(set) var samples: [UWBSample] = []

    init(database: AppDatabase) {
        self.database = database
        super.init()
    }

    func setTruth(distance: Double, los: Bool) {
        self.sollDistanz = distance
        self.los = los
    }

    /// Erzeugt die eigene NISession vorab, damit ihr discoveryToken an den Peer
    /// geschickt werden kann, bevor das Ranging beginnt. Dieselbe Session läuft
    /// später weiter — eine neue Session hätte einen anderen Token als den
    /// bereits verschickten.
    func vorbereiten() -> NIDiscoveryToken? {
        let s = NISession()
        s.delegate = self
        session = s
        return s.discoveryToken
    }

    func start(peerToken: NIDiscoveryToken) {
        guard let s = session else { return }
        s.run(NINearbyPeerConfiguration(peerToken: peerToken))
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func session(_ s: NISession, didUpdate objects: [NINearbyObject]) {
        for o in objects where o.distance != nil {
            record(distance: Double(o.distance!), direction: o.direction)
        }
    }

    func session(_ s: NISession, didInvalidateWith error: Error) {
        onInvalidated?(error)
    }

    func record(distance: Double, direction: simd_float3?) {
        guard let soll = sollDistanz else { return }
        var sample = UWBSample(id: nil, ts: Date().timeIntervalSince1970,
                               peer: "peer", distance: distance,
                               dirX: direction.map { Double($0.x) },
                               dirY: direction.map { Double($0.y) },
                               dirZ: direction.map { Double($0.z) },
                               trueDistance: soll, los: los)
        do {
            try database.writer.write { try sample.insert($0) }
            samples.append(sample)
            onRecorded?()
        } catch {}
    }
}
