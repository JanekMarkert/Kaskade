import MultipeerConnectivity
import NearbyInteraction
import UIKit
import os

/// Tauscht NIDiscoveryToken über MultipeerConnectivity aus — der Weg aus
/// Apples eigenem NearbyInteraction-Beispiel, ohne zusätzliche
/// Infrastruktur (kein eigener Server, läuft über lokales WLAN/Bluetooth).
@MainActor
final class PeerDiscovery: NSObject {
    nonisolated(unsafe) private static let serviceType = "kaskade-uwb"
    nonisolated(unsafe) private static let logger = Logger(subsystem: "de.bht.traveltracker", category: "PeerDiscovery")

    /// Nur eine Seite darf einladen, sonst laden sich bei Sichtkontakt beide
    /// Geräte gleichzeitig gegenseitig ein und MultipeerConnectivity wirft die
    /// zuerst verbundene Session wieder raus.
    private let istInitiator: Bool
    // Kein Initializer-Ausdruck, weil `UIDevice.current.name` MainActor-isoliert
    // ist — die Zuweisung passiert stattdessen in `init`, die selbst schon auf
    // dem MainActor läuft.
    nonisolated(unsafe) private let peerId: MCPeerID
    // MultipeerConnectivity ruft seine Delegate-Methoden von einer eigenen
    // Warteschlange auf, nicht vom Hauptthread. `nonisolated(unsafe)`, damit
    // diese Objekte sowohl von @MainActor-Code (start/stop/sendToken) als
    // auch von den nonisolated Delegate-Callbacks direkt genutzt werden
    // können — sonst stürzt es zur Laufzeit mit `dispatch_assert_queue_fail`.
    nonisolated(unsafe) private lazy var session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
    nonisolated(unsafe) private lazy var advertiser = MCNearbyServiceAdvertiser(
        peer: peerId, discoveryInfo: nil, serviceType: Self.serviceType)
    nonisolated(unsafe) private lazy var browser = MCNearbyServiceBrowser(peer: peerId, serviceType: Self.serviceType)

    nonisolated(unsafe) var onTokenReceived: ((NIDiscoveryToken) -> Void)?
    nonisolated(unsafe) var onConnected: (() -> Void)?
    /// Für sichtbare Diagnose im Feld — sonst ist die Kopplung eine Blackbox.
    nonisolated(unsafe) var onStateChanged: ((MCSessionState) -> Void)?

    init(istInitiator: Bool) {
        self.istInitiator = istInitiator
        self.peerId = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        if istInitiator {
            browser.startBrowsingForPeers()
        }
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func sendToken(_ token: NIDiscoveryToken) {
        guard !session.connectedPeers.isEmpty,
              let daten = try? NSKeyedArchiver.archivedData(
                withRootObject: token, requiringSecureCoding: true)
        else { return }
        try? session.send(daten, toPeers: session.connectedPeers, with: .reliable)
    }
}

// MultipeerConnectivity ruft diese Delegate-Methoden von einer eigenen
// Warteschlange auf, nicht vom Hauptthread — darum `nonisolated`. Sonst
// stürzt es zur Laufzeit mit `dispatch_assert_queue_fail` ab, sobald ein
// Peer gefunden wird.
extension PeerDiscovery: @preconcurrency MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Self.logger.info("Peer \(peerID.displayName) Status: \(state.rawValue)")
        onStateChanged?(state)
        guard state == .connected else { return }
        onConnected?()
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let token = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NIDiscoveryToken.self, from: data)
        else { return }
        onTokenReceived?(token)
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream,
                withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension PeerDiscovery: @preconcurrency MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension PeerDiscovery: @preconcurrency MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
