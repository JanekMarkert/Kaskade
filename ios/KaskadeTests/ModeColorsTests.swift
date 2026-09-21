import Testing
@testable import Kaskade

@Test func jederModusHatEineEigeneFarbe() {
    let modi = ["foot", "bike", "car", "train", "plane"]
    let farben = modi.map { ModeColors.hex(for: $0) }
    #expect(Set(farben).count == modi.count)
    #expect(ModeColors.hex(for: "foot") == "#1b7f79")
    #expect(ModeColors.hex(for: nil) == "#9aa0a6")
}
