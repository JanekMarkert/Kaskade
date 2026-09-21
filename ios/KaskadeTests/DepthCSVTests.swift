import Testing
@testable import Kaskade

@Test func depthCsvHatKopfzeileUndZeilenJeMessung() {
    let proben = [
        DepthSample(id: nil, ts: 100.0, depthM: 2.01, confidence: 2,
                   trueDistance: 2.0, lighting: "tag"),
        DepthSample(id: nil, ts: 101.0, depthM: 2.30, confidence: 1,
                   trueDistance: 2.0, lighting: "nacht"),
    ]
    let csv = DepthCSV.build(samples: proben)
    let zeilen = csv.split(separator: "\n", omittingEmptySubsequences: false)
    #expect(zeilen[0] == "ts,true_distance,depth_m,confidence,lighting")
    #expect(zeilen[1] == "100.0,2.0,2.01,2,tag")
    #expect(zeilen[2] == "101.0,2.0,2.3,1,nacht")
}
