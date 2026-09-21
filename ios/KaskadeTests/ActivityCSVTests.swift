import Testing
@testable import Kaskade

@Test func activityCsvHatKopfzeileUndZeilenJeProbe() {
    let proben = [
        ActivitySample(id: nil, ts: 100.0, cmActivity: "walking", cmConfidence: 2, sessionId: "s"),
        ActivitySample(id: nil, ts: 101.0, cmActivity: "automotive", cmConfidence: 1, sessionId: "s"),
    ]
    let csv = ActivityCSV.build(samples: proben)
    let zeilen = csv.split(separator: "\n", omittingEmptySubsequences: false)
    #expect(zeilen[0] == "ts,cm_activity,cm_confidence")
    #expect(zeilen[1] == "100.0,walking,2")
    #expect(zeilen[2] == "101.0,automotive,1")
}
