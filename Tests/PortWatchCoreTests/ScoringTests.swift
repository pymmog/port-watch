import XCTest
@testable import PortWatchCore

final class ScoringTests: XCTestCase {
    func testOverallMatchesSampleFixture() throws {
        let data = try fixtureData(named: "tracker-sample.json")
        let document = try TrackerSnapshotBuilder.decodeTracker(from: data)
        let result = PortWatchMilestones.overall(efforts: document.efforts)

        XCTAssertEqual(result.score, 72, accuracy: 0.05)
        XCTAssertEqual(result.leader?.effort.id, "cgbj")
        XCTAssertEqual(result.top3, 67.2, accuracy: 0.05)
        XCTAssertEqual(result.furthest.key, "ingame")
        XCTAssertEqual(result.trackedCount, 28)
    }

    func testPlayableAnswerMapping() {
        XCTAssertEqual(PortWatchMilestones.playableAnswer(forFurthestKey: "menu"), "Not yet")
        XCTAssertEqual(PortWatchMilestones.playableAnswer(forFurthestKey: "ingame"), "Sort of")
        XCTAssertEqual(PortWatchMilestones.playableAnswer(forFurthestKey: "fps30"), "Mostly")
        XCTAssertEqual(PortWatchMilestones.playableAnswer(forFurthestKey: "stable"), "Yes")
    }

    func testHistoryFallbackUsesLatestEntry() throws {
        let data = try fixtureData(named: "tracker-sample.json")
        let document = try TrackerSnapshotBuilder.decodeTracker(from: data)

        guard let fallback = TrackerSnapshotBuilder.historyFallback(document: document) else {
            XCTFail("Expected history fallback")
            return
        }

        XCTAssertEqual(fallback.score, 72, accuracy: 0.05)
        XCTAssertEqual(fallback.top3, 67.2, accuracy: 0.05)
        XCTAssertEqual(fallback.furthest.key, "ingame")
        XCTAssertEqual(fallback.leader?.effort.id, "cgbj")
    }

    func testBuildWithoutScriptUsesSwiftMirror() throws {
        let data = try fixtureData(named: "tracker-sample.json")
        let document = try TrackerSnapshotBuilder.decodeTracker(from: data)
        let state = TrackerSnapshotBuilder.build(document: document, scoringScript: nil)

        XCTAssertEqual(state.source, .swiftMirror)
        XCTAssertEqual(state.overall.score, 72, accuracy: 0.05)
    }

    private func fixtureData(named name: String) throws -> Data {
        let base = String(name.split(separator: ".").first ?? Substring(name))
        let ext = name.split(separator: ".").dropFirst().first.map(String.init) ?? "json"
        guard let url = Bundle.module.url(forResource: base, withExtension: ext, subdirectory: "Fixtures") else {
            throw NSError(domain: "Tests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name)"])
        }
        return try Data(contentsOf: url)
    }
}