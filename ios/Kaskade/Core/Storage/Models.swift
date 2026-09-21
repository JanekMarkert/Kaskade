import GRDB

struct Fix: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "fix"
    var id: Int64?
    var ts: Double
    var lat: Double
    var lon: Double
    var alt: Double?
    var hAcc: Double?
    var vAcc: Double?
    var speed: Double?
    var speedAcc: Double?
    var course: Double?
    var courseAcc: Double?
    var sessionId: String

    enum CodingKeys: String, CodingKey {
        case id, ts, lat, lon, alt
        case hAcc = "h_acc", vAcc = "v_acc"
        case speed, speedAcc = "speed_acc"
        case course, courseAcc = "course_acc"
        case sessionId = "session_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct MotionSample: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "motion_sample"
    var id: Int64?
    var ts: Double
    var ax: Double
    var ay: Double
    var az: Double
    var sessionId: String

    enum CodingKeys: String, CodingKey {
        case id, ts, ax, ay, az
        case sessionId = "session_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct ActivitySample: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "activity_sample"
    var id: Int64?
    var ts: Double
    var cmActivity: String
    var cmConfidence: Int
    var sessionId: String

    enum CodingKeys: String, CodingKey {
        case id, ts
        case cmActivity = "cm_activity"
        case cmConfidence = "cm_confidence"
        case sessionId = "session_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct LabelEvent: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "label_event"
    var id: Int64?
    var ts: Double
    var mode: String
    var sessionId: String

    enum CodingKeys: String, CodingKey {
        case id, ts, mode
        case sessionId = "session_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct BeaconSample: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "beacon_sample"
    var id: Int64?
    var ts: Double
    var uuid: String
    var major: Int?
    var minor: Int?
    var rssi: Int
    var clAccuracy: Double?
    var trueDistance: Double
    var los: Bool

    enum CodingKeys: String, CodingKey {
        case id, ts, uuid, major, minor, rssi
        case clAccuracy = "cl_accuracy"
        case trueDistance = "true_distance"
        case los
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct UWBSample: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "uwb_sample"
    var id: Int64?
    var ts: Double
    var peer: String
    var distance: Double?
    var dirX: Double?
    var dirY: Double?
    var dirZ: Double?
    var trueDistance: Double
    var los: Bool

    enum CodingKeys: String, CodingKey {
        case id, ts, peer, distance
        case dirX = "dir_x", dirY = "dir_y", dirZ = "dir_z"
        case trueDistance = "true_distance"
        case los
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct DepthSample: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "depth_sample"
    var id: Int64?
    var ts: Double
    var depthM: Double
    var confidence: Int
    var trueDistance: Double
    var lighting: String

    enum CodingKeys: String, CodingKey {
        case id, ts
        case depthM = "depth_m"
        case confidence
        case trueDistance = "true_distance"
        case lighting
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct Segment: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "segment"
    var id: Int64?
    var startTs: Double
    var endTs: Double
    var kind: String
    var predictedMode: String?
    var confidence: Double?
    var labelMode: String?
    var tripId: Int64?
    var sessionId: String

    enum CodingKeys: String, CodingKey {
        case id
        case startTs = "start_ts"
        case endTs = "end_ts"
        case kind
        case predictedMode = "predicted_mode"
        case confidence
        case labelMode = "label_mode"
        case tripId = "trip_id"
        case sessionId = "session_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct Trip: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "trip"
    var id: Int64?
    var startTs: Double
    var endTs: Double
    var title: String?

    enum CodingKeys: String, CodingKey {
        case id
        case startTs = "start_ts"
        case endTs = "end_ts"
        case title
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}
