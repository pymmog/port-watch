import Foundation

public enum ScoringScript {
    /// Strips ES module `export` keywords so scoring.js can run in JavaScriptCore.
    public static func stripExports(from source: String) -> String {
        source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                if line.hasPrefix("export ") {
                    return String(line.dropFirst("export ".count))
                }
                return String(line)
            }
            .joined(separator: "\n")
    }
}