import Foundation

/// Liest die erste Datenzeile einer CSV mit Kopfzeile als Spaltenname → Wert.
/// Reicht für die Checkliste, die nur die Soll-Werte je Datei braucht — die
/// sind über eine ganze Messdatei hinweg konstant (eine Datei = eine
/// Solldistanz/Sichtbedingung/Beleuchtung).
enum CSVErsteZeile {
    static func lesen(_ url: URL) -> [String: String]? {
        guard let inhalt = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let zeilen = inhalt.split(separator: "\n", omittingEmptySubsequences: true)
        guard zeilen.count >= 2 else { return nil }
        let spalten = zeilen[0].split(separator: ",").map(String.init)
        let werte = zeilen[1].split(separator: ",").map(String.init)
        guard spalten.count == werte.count else { return nil }
        return Dictionary(uniqueKeysWithValues: zip(spalten, werte))
    }
}
