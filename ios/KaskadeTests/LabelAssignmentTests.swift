import Testing
@testable import Kaskade

private func ereignis(_ ts: Double, _ mode: String) -> LabelEvent {
    LabelEvent(id: nil, ts: ts, mode: mode, sessionId: "s")
}

private func segment(_ start: Double, _ ende: Double) -> Segment {
    Segment(id: nil, startTs: start, endTs: ende, kind: "move",
            predictedMode: nil, confidence: nil, labelMode: nil,
            tripId: nil, sessionId: "s")
}

@Test func segmentBekommtDenUeberwiegendGueltigenModus() {
    let events = [ereignis(0, "foot"), ereignis(100, "train")]
    let segmente = LabelAssignment.apply(events: events, to: [segment(80, 200)])
    #expect(segmente[0].labelMode == "train")
}

@Test func segmentVorDemErstenEreignisBleibtUngelabelt() {
    let events = [ereignis(500, "foot")]
    let segmente = LabelAssignment.apply(events: events, to: [segment(0, 100)])
    #expect(segmente[0].labelMode == nil)
}
