import CoreLocation
import CoreMotion
import Foundation
import os

final class TrackingService: NSObject, CLLocationManagerDelegate {
    private static let logger = Logger(subsystem: "de.bht.traveltracker", category: "TrackingService")

    private let database: AppDatabase
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private(set) var isRecording = false
    private var sessionId = ""
    var onAuthorizationDenied: (() -> Void)?

    init(database: AppDatabase) {
        self.database = database
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
    }

    func start(sessionId: String) {
        self.sessionId = sessionId
        isRecording = true
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startMotion()
        startActivity()
    }

    func stop() {
        isRecording = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        motionManager.stopDeviceMotionUpdates()
        activityManager.stopActivityUpdates()
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        handle(locations: locs)
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        guard isRecording, m.authorizationStatus == .denied || m.authorizationStatus == .restricted
        else { return }
        onAuthorizationDenied?()
    }

    func handle(locations: [CLLocation]) {
        guard isRecording else { return }
        let gueltige = locations.filter { $0.horizontalAccuracy >= 0 }
        guard !gueltige.isEmpty else { return }
        do {
            try database.writer.write { db in
                for l in gueltige {
                    var f = Fix(id: nil,
                                ts: l.timestamp.timeIntervalSince1970,
                                lat: l.coordinate.latitude,
                                lon: l.coordinate.longitude,
                                alt: l.verticalAccuracy >= 0 ? l.altitude : nil,
                                hAcc: l.horizontalAccuracy,
                                vAcc: l.verticalAccuracy >= 0 ? l.verticalAccuracy : nil,
                                speed: l.speed >= 0 ? l.speed : nil,
                                speedAcc: l.speedAccuracy >= 0 ? l.speedAccuracy : nil,
                                course: l.course >= 0 ? l.course : nil,
                                courseAcc: l.courseAccuracy >= 0 ? l.courseAccuracy : nil,
                                sessionId: sessionId)
                    try f.insert(db)
                }
            }
        } catch {
            Self.logger.error("Fix konnte nicht geschrieben werden: \(error, privacy: .public)")
        }
    }

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            var s = MotionSample(id: nil,
                                 ts: Date().timeIntervalSince1970,
                                 ax: m.userAcceleration.x,
                                 ay: m.userAcceleration.y,
                                 az: m.userAcceleration.z,
                                 sessionId: self.sessionId)
            do {
                try self.database.writer.write { try s.insert($0) }
            } catch {
                Self.logger.error("Motion-Sample konnte nicht geschrieben werden: \(error, privacy: .public)")
            }
        }
    }

    private func startActivity() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { [weak self] a in
            guard let self, let a else { return }
            var s = ActivitySample(id: nil,
                                   ts: a.startDate.timeIntervalSince1970,
                                   cmActivity: Self.beschreibe(a),
                                   cmConfidence: a.confidence.rawValue,
                                   sessionId: self.sessionId)
            do {
                try self.database.writer.write { try s.insert($0) }
            } catch {
                Self.logger.error("Activity-Sample konnte nicht geschrieben werden: \(error, privacy: .public)")
            }
        }
    }

    static func beschreibe(_ a: CMMotionActivity) -> String {
        if a.automotive { return "automotive" }
        if a.cycling { return "cycling" }
        if a.running { return "running" }
        if a.walking { return "walking" }
        if a.stationary { return "stationary" }
        return "unknown"
    }
}
