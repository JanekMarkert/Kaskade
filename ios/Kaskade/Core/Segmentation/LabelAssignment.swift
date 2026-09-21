import Foundation

enum LabelAssignment {
    static func apply(events: [LabelEvent], to segments: [Segment]) -> [Segment] {
        let sortiert = events.sorted { $0.ts < $1.ts }
        guard !sortiert.isEmpty else { return segments }

        return segments.map { segment in
            var dauern: [String: Double] = [:]
            for (i, e) in sortiert.enumerated() {
                let bis = i + 1 < sortiert.count ? sortiert[i + 1].ts : .greatestFiniteMagnitude
                let von = max(segment.startTs, e.ts)
                let nach = min(segment.endTs, bis)
                if nach > von { dauern[e.mode, default: 0] += nach - von }
            }
            var kopie = segment
            kopie.labelMode = dauern.max { $0.value < $1.value }?.key
            return kopie
        }
    }
}
