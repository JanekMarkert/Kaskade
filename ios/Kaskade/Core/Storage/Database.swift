import Foundation
import GRDB

struct AppDatabase {
    let writer: DatabaseWriter
    var reader: DatabaseReader { writer }

    static let shared: AppDatabase = {
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("traveltracker.sqlite")
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return try! AppDatabase(DatabaseQueue(path: url.path))
    }()

    static func makeInMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "fix") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull().indexed()
                t.column("lat", .double).notNull()
                t.column("lon", .double).notNull()
                t.column("alt", .double)
                t.column("h_acc", .double)
                t.column("v_acc", .double)
                t.column("speed", .double)
                t.column("speed_acc", .double)
                t.column("course", .double)
                t.column("course_acc", .double)
                t.column("session_id", .text).notNull().indexed()
            }
            try db.create(table: "motion_sample") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull().indexed()
                t.column("ax", .double).notNull()
                t.column("ay", .double).notNull()
                t.column("az", .double).notNull()
                t.column("session_id", .text).notNull().indexed()
            }
            try db.create(table: "activity_sample") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull().indexed()
                t.column("cm_activity", .text).notNull()
                t.column("cm_confidence", .integer).notNull()
                t.column("session_id", .text).notNull()
            }
            try db.create(table: "label_event") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull().indexed()
                t.column("mode", .text).notNull()
                t.column("session_id", .text).notNull()
            }
            try db.create(table: "beacon_sample") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull()
                t.column("uuid", .text).notNull()
                t.column("major", .integer)
                t.column("minor", .integer)
                t.column("rssi", .integer).notNull()
                t.column("cl_accuracy", .double)
                t.column("true_distance", .double).notNull()
                t.column("los", .boolean).notNull()
            }
            try db.create(table: "uwb_sample") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull()
                t.column("peer", .text).notNull()
                t.column("distance", .double)
                t.column("dir_x", .double)
                t.column("dir_y", .double)
                t.column("dir_z", .double)
                t.column("true_distance", .double).notNull()
                t.column("los", .boolean).notNull()
            }
            try db.create(table: "depth_sample") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("ts", .double).notNull()
                t.column("depth_m", .double).notNull()
                t.column("confidence", .integer).notNull()
                t.column("true_distance", .double).notNull()
                t.column("lighting", .text).notNull()
            }
            try db.create(table: "trip") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("start_ts", .double).notNull()
                t.column("end_ts", .double).notNull()
                t.column("title", .text)
            }
            try db.create(table: "segment") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("start_ts", .double).notNull()
                t.column("end_ts", .double).notNull()
                t.column("kind", .text).notNull()
                t.column("predicted_mode", .text)
                t.column("confidence", .double)
                t.column("label_mode", .text)
                t.column("trip_id", .integer).references("trip")
                t.column("session_id", .text).notNull()
            }
        }
        return m
    }
}
