import Foundation

struct M1Fix {
    let ts: Double
    let lat: Double
    let lon: Double
    let hAcc: Double
}

enum M1CSV {
    static func build(fixes: [M1Fix], pointId: String, session: String) -> String {
        var zeilen = ["ts,lat,lon,h_acc,point_id,session"]
        for f in fixes {
            zeilen.append("\(f.ts),\(f.lat),\(f.lon),\(f.hAcc),\(pointId),\(session)")
        }
        return zeilen.joined(separator: "\n")
    }
}
