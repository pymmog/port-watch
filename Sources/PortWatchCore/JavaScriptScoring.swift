import Foundation

#if canImport(JavaScriptCore)
import JavaScriptCore

public enum JavaScriptScoringError: Error, LocalizedError {
    case contextCreationFailed
    case scriptEvaluationFailed(String)
    case overallMissing
    case resultInvalid(String)

    public var errorDescription: String? {
        switch self {
        case .contextCreationFailed:
            return "Could not create JavaScript context."
        case .scriptEvaluationFailed(let msg):
            return "Scoring script failed: \(msg)"
        case .overallMissing:
            return "Scoring script did not define overall()."
        case .resultInvalid(let msg):
            return "Invalid scoring result: \(msg)"
        }
    }
}

/// Evaluates the live PortWatch scoring.js in JavaScriptCore so numbers match the site.
public enum JavaScriptScoring {
    public static func evaluate(scoringScript: String, efforts: [Effort]) throws -> PortWatchMilestones.OverallScore {
        guard let context = JSContext() else {
            throw JavaScriptScoringError.contextCreationFailed
        }

        let errorBox = UncheckedSendableBox<String?>(nil)
        context.exceptionHandler = { _, value in
            errorBox.value = value?.toString()
        }

        let stripped = ScoringScript.stripExports(from: scoringScript)
        context.evaluateScript(stripped)

        if let lastError = errorBox.value {
            throw JavaScriptScoringError.scriptEvaluationFailed(lastError)
        }

        guard let overallFn = context.objectForKeyedSubscript("overall"),
              !overallFn.isUndefined
        else {
            throw JavaScriptScoringError.overallMissing
        }

        let effortsJSON = try JSONEncoder().encode(efforts)
        let jsonObject = try JSONSerialization.jsonObject(with: effortsJSON)
        guard let effortsValue = JSValue(object: jsonObject, in: context) else {
            throw JavaScriptScoringError.resultInvalid("Could not bridge efforts into JavaScript.")
        }

        guard let result = overallFn.call(withArguments: [effortsValue]) else {
            throw JavaScriptScoringError.resultInvalid(errorBox.value ?? "overall() returned nil")
        }

        if let lastError = errorBox.value {
            throw JavaScriptScoringError.scriptEvaluationFailed(lastError)
        }

        return try parseOverall(result, originalEfforts: efforts)
    }

    private static func parseOverall(_ value: JSValue, originalEfforts: [Effort]) throws -> PortWatchMilestones.OverallScore {
        guard !value.isUndefined, !value.isNull else {
            throw JavaScriptScoringError.resultInvalid("overall() returned null")
        }

        let score = value.objectForKeyedSubscript("score")?.toDouble() ?? 0
        let top3 = value.objectForKeyedSubscript("top3")?.toDouble() ?? 0

        var leader: PortWatchMilestones.ScoredEffort?
        if let leaderValue = value.objectForKeyedSubscript("leader"), !leaderValue.isUndefined, !leaderValue.isNull {
            let leaderScore = leaderValue.objectForKeyedSubscript("score")?.toDouble() ?? score
            let reached = leaderValue.objectForKeyedSubscript("reached")?.toString() ?? "groundwork"
            let reachedLabel = leaderValue.objectForKeyedSubscript("reachedLabel")?.toString() ?? reached
            let effortId = leaderValue.objectForKeyedSubscript("effort")?.objectForKeyedSubscript("id")?.toString()
            let effort = originalEfforts.first { $0.id == effortId }
                ?? originalEfforts.first { $0.name == leaderValue.objectForKeyedSubscript("effort")?.objectForKeyedSubscript("name")?.toString() }
            if let effort {
                leader = .init(
                    effort: effort,
                    score: leaderScore,
                    groundwork: leaderValue.objectForKeyedSubscript("groundwork")?.toDouble() ?? 0,
                    reached: reached,
                    reachedLabel: reachedLabel
                )
            }
        }

        let furthestKey = value.objectForKeyedSubscript("furthest")?.objectForKeyedSubscript("key")?.toString() ?? "groundwork"
        let furthest = PortWatchMilestones.milestone(forKey: furthestKey) ?? PortWatchMilestones.all[0]

        let tracked = originalEfforts.filter { !$0.isNuked }.count

        return PortWatchMilestones.OverallScore(
            leader: leader,
            score: score,
            top3: top3,
            furthest: furthest,
            trackedCount: tracked
        )
    }
}

/// Holds JS exception text from a JavaScriptCore handler (main-thread only).
private final class UncheckedSendableBox<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}
#endif