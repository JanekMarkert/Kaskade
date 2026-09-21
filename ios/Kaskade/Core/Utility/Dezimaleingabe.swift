import Foundation

extension String {
    /// Das `.decimalPad`-Tastaturlayout liefert bei deutscher Spracheinstellung
    /// ein Komma als Dezimaltrennzeichen, `Double.init(String)` versteht aber
    /// nur den Punkt und gibt sonst lautlos `nil` zurück.
    var alsDezimalzahl: Double? {
        Double(replacingOccurrences(of: ",", with: "."))
    }
}
