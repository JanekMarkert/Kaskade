import ARKit
import SwiftUI

/// Zeigt das Kamerabild der laufenden ARSession, damit sichtbar ist, worauf das
/// Fadenkreuz — und damit die zentrale Tiefenmessung — tatsächlich zeigt.
struct DepthCameraPreview: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.session = session
        view.automaticallyUpdatesLighting = false
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
