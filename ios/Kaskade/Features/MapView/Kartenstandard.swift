import CoreLocation

/// Default-Kartenausschnitt, solange keine (oder noch keine) Messdaten
/// vorliegen — die App wird ausschließlich in Berlin genutzt, eine
/// Weltkarte als Startansicht ist nie sinnvoll.
let berlinMitte = CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405)
let berlinZoom: Double = 10
