import SwiftUI

private let modiInReihenfolge = ["foot", "bike", "car", "train", "plane"]
private let beschriftung: [String: String] = [
    "foot": "Fuß", "bike": "Rad", "car": "Auto", "train": "Zug", "plane": "Flug",
]

struct LabelBarView: View {
    let database: AppDatabase
    let sessionId: String

    @State private var aktiverModus: String?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(modiInReihenfolge, id: \.self) { modus in
                Button {
                    label(modus)
                } label: {
                    Text(beschriftung[modus] ?? modus)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(ModeColors.color(for: modus).opacity(
                            aktiverModus == modus ? 1.0 : 0.5))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
    }

    private func label(_ modus: String) {
        aktiverModus = modus
        var ereignis = LabelEvent(id: nil, ts: Date().timeIntervalSince1970,
                                  mode: modus, sessionId: sessionId)
        try? database.writer.write { try ereignis.insert($0) }
    }
}
