import XCTest
@testable import PortWatchCore

final class JavaScriptStripTests: XCTestCase {
    func testStripExportsRemovesExportKeyword() {
        let input = """
        export const MILESTONES = [];
        export function overall(e) { return e; }
        const x = 1;
        """
        let output = ScoringScript.stripExports(from: input)
        XCTAssertFalse(output.contains("export "))
        XCTAssertTrue(output.contains("function overall"))
        XCTAssertTrue(output.contains("const MILESTONES"))
    }
}