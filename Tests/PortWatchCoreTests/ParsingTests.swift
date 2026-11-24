import XCTest
@testable import PortWatchCore

final class ParsingTests: XCTestCase {
    func testDecodesFullTrackerFixture() throws {
        let data = try fixtureData(named: "tracker-sample.json")
        let doc = try TrackerSnapshotBuilder.decodeTracker(from: data)

        XCTAssertEqual(doc.efforts.count, 30)
        XCTAssertEqual(doc.efforts.filter(\.isNuked).count, 2)
        XCTAssertEqual(doc.efforts.filter { !$0.isNuked }.count, 28)

        let nuked = doc.efforts.filter(\.isNuked).map(\.id).sorted()
        XCTAssertEqual(nuked, ["americas-recomp", "leonida"])

        XCTAssertFalse(doc.exe.status.isEmpty)
        XCTAssertGreaterThan(doc.news.count, 0)
        XCTAssertGreaterThan(doc.history.count, 0)
    }

    func testDecodesUpdatedTimestampWithFractionalSeconds() throws {
        let json = """
        {
          "efforts": [],
          "exe": { "status": "released" },
          "news": [],
          "history": [],
          "updated": "2026-11-24T13:29:54.857Z"
        }
        """.data(using: .utf8)!

        let doc = try TrackerSnapshotBuilder.decodeTracker(from: json)
        XCTAssertEqual(doc.exe.status, "released")
        XCTAssertGreaterThan(doc.updated.timeIntervalSince1970, 1_700_000_000)
    }

    func testNewsURL() {
        let item = NewsItem(id: "2026-11-24-cgbj-in-game", date: "2026-11-24", title: "Test")
        XCTAssertEqual(
            item.url().absoluteString,
            "https://portwatch-vi.xyz/news/2026-11-24-cgbj-in-game.html"
        )
    }

    func testNukedObjectDecodesLikeSite() throws {
        let json = """
        {
          "id": "leonida",
          "name": "Leonida",
          "nuked": { "at": "2026-11-23", "note": "gone" }
        }
        """.data(using: .utf8)!

        let effort = try JSONDecoder().decode(Effort.self, from: json)
        XCTAssertTrue(effort.isNuked)
        XCTAssertEqual(effort.nuked?.at, "2026-11-23")
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