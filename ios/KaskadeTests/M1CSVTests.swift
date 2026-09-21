import Testing
@testable import Kaskade

@Test func csvHatKopfzeileUndKorrekteSpalten() {
    let fixes = [
        M1Fix(ts: 100.0, lat: 52.545, lon: 13.355, hAcc: 4.2),
        M1Fix(ts: 101.0, lat: 52.5451, lon: 13.3551, hAcc: 3.8),
    ]
    let csv = M1CSV.build(fixes: fixes, pointId: "p1", session: "s1")
    let zeilen = csv.split(separator: "\n", omittingEmptySubsequences: false)

    #expect(zeilen[0] == "ts,lat,lon,h_acc,point_id,session")
    #expect(zeilen.count == 3)
    #expect(zeilen[1] == "100.0,52.545,13.355,4.2,p1,s1")
    #expect(zeilen[2] == "101.0,52.5451,13.3551,3.8,p1,s1")
}

@Test func leereFixlisteGibtNurKopfzeile() {
    let csv = M1CSV.build(fixes: [], pointId: "p2", session: "s2")
    #expect(csv == "ts,lat,lon,h_acc,point_id,session")
}
