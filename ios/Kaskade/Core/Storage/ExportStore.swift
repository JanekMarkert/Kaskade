import Foundation

/// Sammelt alle exportierten Mess-Dateien an einem festen Ort im App-Sandbox
/// statt im flüchtigen `temporaryDirectory` — sonst räumt das System sie
/// irgendwann weg, und es gibt keine Übersicht, was an einem Messtag schon
/// exportiert wurde.
enum ExportStore {
    private static var verzeichnis: URL {
        let basis = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ordner = basis.appendingPathComponent("Exporte", isDirectory: true)
        try? FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        return ordner
    }

    private static let tagFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Unterordner für den heutigen Tag, z. B. `Exporte/2026-09-14/` — trennt
    /// die Exporte je Messtag, statt alles in einen Ordner zu häufen.
    private static var tagesordner: URL {
        let ordner = verzeichnis.appendingPathComponent(tagFormat.string(from: Date()), isDirectory: true)
        try? FileManager.default.createDirectory(at: ordner, withIntermediateDirectories: true)
        return ordner
    }

    @discardableResult
    static func save(_ inhalt: String, name: String) -> URL {
        let url = tagesordner.appendingPathComponent(name)
        try? inhalt.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @discardableResult
    static func save(_ daten: Data, name: String) -> URL {
        let url = tagesordner.appendingPathComponent(name)
        try? daten.write(to: url)
        return url
    }

    static func alle() -> [URL] { dateien(in: verzeichnis, rekursiv: true) }

    /// Exportierte Tagesordner, neuester zuerst, mit ihren Dateien.
    static func nachTag() -> [(tag: String, dateien: [URL])] {
        let ordner = (try? FileManager.default.contentsOfDirectory(
            at: verzeichnis, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        return ordner
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .map { ($0.lastPathComponent, dateien(in: $0, rekursiv: false)) }
    }

    private static func dateien(in ordner: URL, rekursiv: Bool) -> [URL] {
        var optionen: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        if !rekursiv { optionen.insert(.skipsSubdirectoryDescendants) }
        let alle = FileManager.default.enumerator(
            at: ordner, includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: optionen)?.allObjects as? [URL] ?? []
        let dateien = alle.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory != true }
        return dateien.sorted { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return da > db
        }
    }

    /// Ordnet den Dateinamen-Präfixen (aus M1CSV/M3CSV/DepthCSV/TripDetailView)
    /// eine lesbare Herkunft zu, statt nur den rohen Dateinamen zu zeigen.
    static func herkunft(fürDatei name: String) -> String {
        if name.hasSuffix("_ort.geojson") { return "Messort" }
        if name.hasPrefix("m1-") { return "GNSS-Genauigkeit (M1)" }
        if name.hasPrefix("m3_") { return "UWB / BLE (M3)" }
        if name.hasPrefix("m4_") { return "LiDAR (M4)" }
        if name.hasPrefix("trip_") { return "GPS-Aufzeichnung" }
        return "Sonstiges"
    }
}
