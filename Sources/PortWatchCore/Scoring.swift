import Foundation

// Mirrors https://portwatch-vi.xyz/assets/js/scoring.js

public struct Milestone: Equatable, Sendable {
    public let key: String
    public let label: String
    public let at: Double
}

public enum PortWatchMilestones {
    public static let all: [Milestone] = [
        .init(key: "groundwork", label: "Groundwork", at: 0),
        .init(key: "loads", label: "Exe runs", at: 25),
        .init(key: "boots", label: "First frame", at: 40),
        .init(key: "menu", label: "Main menu", at: 55),
        .init(key: "ingame", label: "In-game", at: 70),
        .init(key: "fps30", label: "30 FPS", at: 85),
        .init(key: "stable", label: "Stable", at: 100),
    ]

    private static let tick: [String: Double] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.key, $0.at) }
    )

    private static let ladder: [String] = ["loads", "boots", "menu", "ingame"]

    private struct GroundworkPart {
        let key: String
        let weight: Double
    }

    private static let groundworkParts: [GroundworkPart] = [
        .init(key: "loader", weight: 0.2),
        .init(key: "shaders", weight: 0.28),
        .init(key: "graphics", weight: 0.32),
        .init(key: "proven", weight: 0.2),
    ]

    private static let stability: [String: Double] = [
        "unknown": 0,
        "constant": 0,
        "often": 0.25,
        "sometimes": 0.55,
        "rarely": 0.8,
        "stable": 1,
    ]

    public static func milestone(forKey key: String) -> Milestone? {
        all.first { $0.key == key }
    }

    public static func furthestMilestoneIndex(key: String) -> Int {
        all.firstIndex { $0.key == key } ?? 0
    }

    public static func ladderValue(_ value: LadderValue?) -> Double {
        guard let value else { return 0 }
        switch value {
        case .bool(let b):
            return b ? 1 : 0
        case .number(let n):
            return clamp01(n)
        }
    }

    public static func groundworkFraction(_ gw: GroundworkParts?) -> Double {
        guard let gw else { return 0 }
        let values: [String: Double?] = [
            "loader": gw.loader,
            "shaders": gw.shaders,
            "graphics": gw.graphics,
            "proven": gw.proven,
        ]
        return groundworkParts.reduce(0) { sum, part in
            sum + part.weight * clamp01(values[part.key] ?? nil)
        }
    }

    public struct ScoredEffort: Equatable, Sendable {
        public let effort: Effort
        public let score: Double
        public let groundwork: Double
        public let reached: String
        public let reachedLabel: String
    }

    public static func scoreEffort(_ effort: Effort) -> ScoredEffort {
        let gw = groundworkFraction(effort.groundwork)
        let gta = effort.gta ?? GTAMilestones()
        var score = (tick["loads"] ?? 25) * gw
        var reached = "groundwork"
        var prevTick = score

        for key in ladder {
            let v = ladderValue(value(for: key, in: gta))
            let tickValue = tick[key] ?? 0
            if v >= 1 {
                score = tickValue
                prevTick = score
                reached = key
                continue
            }
            if v > 0 {
                score = max(score, prevTick + v * (tickValue - prevTick))
            }
            break
        }

        if reached == "ingame" {
            let fps = clamp01((gta.fps ?? 0) / 30)
            let stab = stability[gta.stability ?? "unknown"] ?? 0
            let ingameAt = tick["ingame"] ?? 70
            let fps30At = tick["fps30"] ?? 85
            let stableAt = tick["stable"] ?? 100
            score = ingameAt + fps * (fps30At - ingameAt) + stab * (stableAt - fps30At)
            if fps >= 1 { reached = "fps30" }
            if fps >= 1, stab >= 1 { reached = "stable" }
        }

        let rounded = (score * 10).rounded() / 10
        let label = milestone(forKey: reached)?.label ?? reached

        return ScoredEffort(
            effort: effort,
            score: rounded,
            groundwork: gw,
            reached: reached,
            reachedLabel: label
        )
    }

    public struct OverallScore: Equatable, Sendable {
        public let leader: ScoredEffort?
        public let score: Double
        public let top3: Double
        public let furthest: Milestone
        public let trackedCount: Int
    }

    public static func overall(efforts: [Effort]) -> OverallScore {
        let scored = efforts
            .filter { !$0.isNuked }
            .map { scoreEffort($0) }
            .sorted { a, b in
                if a.score != b.score { return a.score > b.score }
                return (b.effort.stats?.stars ?? 0) > (a.effort.stats?.stars ?? 0)
            }

        let top = Array(scored.prefix(3))
        let leader = scored.first
        var furthestIndex = 0
        for item in scored {
            let idx = furthestMilestoneIndex(key: item.reached)
            if idx > furthestIndex { furthestIndex = idx }
        }

        let top3Average: Double
        if top.isEmpty {
            top3Average = 0
        } else {
            let sum = top.reduce(0.0) { $0 + $1.score }
            top3Average = (sum / Double(top.count) * 10).rounded() / 10
        }

        let furthest = all[furthestIndex]

        return OverallScore(
            leader: leader,
            score: leader?.score ?? 0,
            top3: top3Average,
            furthest: furthest,
            trackedCount: efforts.filter { !$0.isNuked }.count
        )
    }

    /// One-line answer shown on the website.
    public static func playableAnswer(forFurthestKey key: String) -> String {
        switch key {
        case "ingame":
            return "Sort of"
        case "fps30":
            return "Mostly"
        case "stable":
            return "Yes"
        default:
            return "Not yet"
        }
    }

    private static func value(for key: String, in gta: GTAMilestones) -> LadderValue? {
        switch key {
        case "loads": return gta.loads
        case "boots": return gta.boots
        case "menu": return gta.menu
        case "ingame": return gta.ingame
        default: return nil
        }
    }

    private static func clamp01(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return 0 }
        return min(1, max(0, value))
    }
}

public enum ScoreComputationSource: String, Equatable, Sendable {
    case liveJavaScript
    case swiftMirror
    case historyFallback
}