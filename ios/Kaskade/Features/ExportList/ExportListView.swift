import SwiftUI

struct ExportListView: View {
    @State private var gruppen: [(tag: String, dateien: [URL])] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(gruppen, id: \.tag) { gruppe in
                    Section {
                        ForEach(gruppe.dateien, id: \.self) { url in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ExportStore.herkunft(fürDatei: url.lastPathComponent))
                                        .font(.subheadline.weight(.medium))
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                ShareLink(item: url)
                            }
                        }
                    } header: {
                        HStack {
                            Text(gruppe.tag)
                            Spacer()
                            ShareLink(items: gruppe.dateien) {
                                Label("Tag teilen", systemImage: "square.and.arrow.up.on.square")
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                }
            }
            .overlay {
                if gruppen.isEmpty {
                    ContentUnavailableView("Noch keine Exporte", systemImage: "tray",
                                           description: Text("Exportierte CSV- und GeoJSON-Dateien sammeln sich hier, nach Tag sortiert."))
                }
            }
            .navigationTitle("Exporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("done-button")
                }
                if !gruppen.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        ShareLink(items: gruppen.flatMap(\.dateien)) {
                            Label("Alle teilen", systemImage: "square.and.arrow.up.on.square")
                        }
                    }
                }
            }
            .onAppear { gruppen = ExportStore.nachTag() }
        }
    }
}
