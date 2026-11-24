import Foundation

public struct LiveTrackerState: Equatable, Sendable {
    public var document: TrackerDocument
    public var overall: PortWatchMilestones.OverallScore
    public var source: ScoreComputationSource
    public var fetchedAt: Date

    public var playableAnswer: String {
        PortWatchMilestones.playableAnswer(forFurthestKey: overall.furthest.key)
    }

    public var newestNews: [NewsItem] {
        Array(document.news.prefix(3))
    }

    public init(
        document: TrackerDocument,
        overall: PortWatchMilestones.OverallScore,
        source: ScoreComputationSource,
        fetchedAt: Date
    ) {
        self.document = document
        self.overall = overall
        self.source = source
        self.fetchedAt = fetchedAt
    }
}

public enum TrackerSnapshotBuilder {
    public struct FetchConfig {
        public var trackerURL: URL
        public var scoringURL: URL
        public var session: URLSession

        public init(
            trackerURL: URL = PortWatchURLs.trackerJSON,
            scoringURL: URL = PortWatchURLs.scoringJS,
            session: URLSession = .shared
        ) {
            self.trackerURL = trackerURL
            self.scoringURL = scoringURL
            self.session = session
        }
    }

    public static func decodeTracker(from data: Data) throws -> TrackerDocument {
        try JSONDecoder().decode(TrackerDocument.self, from: data)
    }

    public static func historyFallback(document: TrackerDocument) -> PortWatchMilestones.OverallScore? {
        guard let latest = document.history.last else { return nil }
        let leaderEffort = document.efforts.first { $0.id == latest.leaderId }
        let furthest = PortWatchMilestones.milestone(forKey: latest.furthest) ?? PortWatchMilestones.all[0]

        let leader: PortWatchMilestones.ScoredEffort?
        if let leaderEffort {
            let scored = PortWatchMilestones.scoreEffort(leaderEffort)
            leader = PortWatchMilestones.ScoredEffort(
                effort: leaderEffort,
                score: latest.leader,
                groundwork: scored.groundwork,
                reached: scored.reached,
                reachedLabel: scored.reachedLabel
            )
        } else {
            leader = nil
        }

        return PortWatchMilestones.OverallScore(
            leader: leader,
            score: latest.leader,
            top3: latest.top3,
            furthest: furthest,
            trackedCount: latest.tracked ?? document.efforts.filter { !$0.isNuked }.count
        )
    }

    public static func build(document: TrackerDocument, scoringScript: String?) -> LiveTrackerState {
        let fetchedAt = Date.now

        if let scoringScript, !scoringScript.isEmpty {
            #if canImport(JavaScriptCore)
            if let js = try? JavaScriptScoring.evaluate(scoringScript: scoringScript, efforts: document.efforts) {
                return LiveTrackerState(document: document, overall: js, source: .liveJavaScript, fetchedAt: fetchedAt)
            }
            if let fallback = historyFallback(document: document) {
                return LiveTrackerState(
                    document: document,
                    overall: fallback,
                    source: .historyFallback,
                    fetchedAt: fetchedAt
                )
            }
            #endif
        }

        let swift = PortWatchMilestones.overall(efforts: document.efforts)
        return LiveTrackerState(document: document, overall: swift, source: .swiftMirror, fetchedAt: fetchedAt)
    }

    public static func fetch(config: FetchConfig = FetchConfig()) async throws -> LiveTrackerState {
        // Sequential requests: avoids sending non-Sendable URLSession across parallel child tasks.
        let session = config.session
        let (data, response) = try await session.data(from: config.trackerURL)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw URLError(.badServerResponse)
        }

        let document = try decodeTracker(from: data)

        let script: String?
        do {
            let (scoringData, scoringResponse) = try await session.data(from: config.scoringURL)
            if let http = scoringResponse as? HTTPURLResponse, http.statusCode >= 400 {
                script = nil
            } else {
                script = String(data: scoringData, encoding: .utf8)
            }
        } catch {
            script = nil
        }

        return build(document: document, scoringScript: script)
    }
}