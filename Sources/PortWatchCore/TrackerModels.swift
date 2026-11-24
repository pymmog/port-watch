import Foundation

// MARK: - Tracker document

public struct TrackerDocument: Codable, Sendable, Equatable {
    public var efforts: [Effort]
    public var exe: ExeStatus
    public var news: [NewsItem]
    public var history: [HistorySnapshot]
    public var updated: Date

    enum CodingKeys: String, CodingKey {
        case efforts, exe, news, history, updated
    }

    public init(
        efforts: [Effort],
        exe: ExeStatus,
        news: [NewsItem],
        history: [HistorySnapshot],
        updated: Date
    ) {
        self.efforts = efforts
        self.exe = exe
        self.news = news
        self.history = history
        self.updated = updated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        efforts = (try? container.decode([Effort].self, forKey: .efforts)) ?? []
        exe = (try? container.decode(ExeStatus.self, forKey: .exe)) ?? ExeStatus(status: "unknown")
        news = (try? container.decode([NewsItem].self, forKey: .news)) ?? []
        history = (try? container.decode([HistorySnapshot].self, forKey: .history)) ?? []

        if let updatedString = try? container.decode(String.self, forKey: .updated),
           let date = TrackerDocument.parseISO8601(updatedString) {
            updated = date
        } else {
            updated = .distantPast
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(efforts, forKey: .efforts)
        try container.encode(exe, forKey: .exe)
        try container.encode(news, forKey: .news)
        try container.encode(history, forKey: .history)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: updated), forKey: .updated)
    }

    private static func parseISO8601(_ string: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: string) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}

public struct ExeStatus: Codable, Sendable, Equatable {
    public var status: String
    public var note: String?

    public init(status: String, note: String? = nil) {
        self.status = status
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case status, note
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = LenientDecoding.optionalString(from: container, forKey: .status) ?? "unknown"
        note = LenientDecoding.optionalString(from: container, forKey: .note)
    }
}

/// Matches `nuked: { at, note }` on the site (truthy → excluded from ranking).
public struct NukedInfo: Codable, Sendable, Equatable {
    public var at: String?
    public var note: String?

    public init(at: String? = nil, note: String? = nil) {
        self.at = at
        self.note = note
    }
}

public struct Effort: Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var repo: String?
    public var link: String?
    public var tier: String?
    public var gta: GTAMilestones?
    public var groundwork: GroundworkParts?
    public var stats: EffortStats?
    public var nuked: NukedInfo?

    public init(
        id: String,
        name: String,
        repo: String? = nil,
        link: String? = nil,
        tier: String? = nil,
        gta: GTAMilestones? = nil,
        groundwork: GroundworkParts? = nil,
        stats: EffortStats? = nil,
        nuked: NukedInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.repo = repo
        self.link = link
        self.tier = tier
        self.gta = gta
        self.groundwork = groundwork
        self.stats = stats
        self.nuked = nuked
    }

    /// Same as `!e.nuked` in scoring.js (null/undefined/false → ranked; object → not ranked).
    public var isNuked: Bool { nuked != nil }

    enum CodingKeys: String, CodingKey {
        case id, name, repo, link, tier, gta, groundwork, stats, nuked
    }
}

extension Effort: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = (try? container.decode(String.self, forKey: .name)) ?? id
        repo = LenientDecoding.optionalString(from: container, forKey: .repo)
        link = LenientDecoding.optionalString(from: container, forKey: .link)
        tier = LenientDecoding.optionalString(from: container, forKey: .tier)
        gta = try? container.decode(GTAMilestones.self, forKey: .gta)
        groundwork = try container.decodeIfPresent(GroundworkParts.self, forKey: .groundwork)
        stats = try? container.decode(EffortStats.self, forKey: .stats)
        nuked = LenientDecoding.decodeNuked(from: container, forKey: .nuked)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(repo, forKey: .repo)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encodeIfPresent(tier, forKey: .tier)
        try container.encodeIfPresent(gta, forKey: .gta)
        try container.encodeIfPresent(groundwork, forKey: .groundwork)
        try container.encodeIfPresent(stats, forKey: .stats)
        try container.encodeIfPresent(nuked, forKey: .nuked)
    }
}

public struct EffortStats: Codable, Sendable, Equatable {
    public var stars: Int?

    enum CodingKeys: String, CodingKey {
        case stars
    }

    public init(stars: Int? = nil) {
        self.stars = stars
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stars = LenientDecoding.optionalInt(from: container, forKey: .stars)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(stars, forKey: .stars)
    }
}

public struct GTAMilestones: Codable, Sendable, Equatable {
    public var loads: LadderValue?
    public var boots: LadderValue?
    public var menu: LadderValue?
    public var ingame: LadderValue?
    public var fps: Double?
    public var stability: String?

    enum CodingKeys: String, CodingKey {
        case loads, boots, menu, ingame, fps, stability
    }

    public init(
        loads: LadderValue? = nil,
        boots: LadderValue? = nil,
        menu: LadderValue? = nil,
        ingame: LadderValue? = nil,
        fps: Double? = nil,
        stability: String? = nil
    ) {
        self.loads = loads
        self.boots = boots
        self.menu = menu
        self.ingame = ingame
        self.fps = fps
        self.stability = stability
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        loads = try? container.decode(LadderValue.self, forKey: .loads)
        boots = try? container.decode(LadderValue.self, forKey: .boots)
        menu = try? container.decode(LadderValue.self, forKey: .menu)
        ingame = try? container.decode(LadderValue.self, forKey: .ingame)
        fps = LenientDecoding.optionalDouble(from: container, forKey: .fps)
        stability = LenientDecoding.optionalString(from: container, forKey: .stability)
    }
}

/// GTA ladder values: false / true / null or 0–1 partial progress.
public enum LadderValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case number(Double)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .number(Double(i))
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if container.decodeNil() {
            self = .number(0)
        } else if let text = try? container.decode(String.self), let n = Double(text) {
            self = .number(n)
        } else {
            self = .number(0)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b):
            try container.encode(b)
        case .number(let n):
            try container.encode(n)
        }
    }
}

public struct GroundworkParts: Codable, Sendable, Equatable {
    public var loader: Double?
    public var shaders: Double?
    public var graphics: Double?
    public var proven: Double?

    enum CodingKeys: String, CodingKey {
        case loader, shaders, graphics, proven
    }

    public init(
        loader: Double? = nil,
        shaders: Double? = nil,
        graphics: Double? = nil,
        proven: Double? = nil
    ) {
        self.loader = loader
        self.shaders = shaders
        self.graphics = graphics
        self.proven = proven
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        loader = LenientDecoding.optionalDouble(from: container, forKey: .loader)
        shaders = LenientDecoding.optionalDouble(from: container, forKey: .shaders)
        graphics = LenientDecoding.optionalDouble(from: container, forKey: .graphics)
        proven = LenientDecoding.optionalDouble(from: container, forKey: .proven)
    }
}

public struct NewsItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var date: String
    public var title: String
    public var category: String?

    enum CodingKeys: String, CodingKey {
        case id, date, title, category
    }

    public init(id: String, date: String, title: String, category: String? = nil) {
        self.id = id
        self.date = date
        self.title = title
        self.category = category
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        date = LenientDecoding.optionalString(from: container, forKey: .date) ?? ""
        title = LenientDecoding.optionalString(from: container, forKey: .title) ?? "(Untitled)"
        category = LenientDecoding.optionalString(from: container, forKey: .category)
    }

    public func url(base: URL = PortWatchURLs.siteRoot) -> URL {
        base.appending(path: "news/\(id).html")
    }
}

public struct HistorySnapshot: Codable, Sendable, Equatable {
    public var date: String
    public var leader: Double
    public var leaderId: String
    public var top3: Double
    public var furthest: String
    public var tracked: Int?

    enum CodingKeys: String, CodingKey {
        case date, leader, leaderId, top3, furthest, tracked
    }

    public init(
        date: String,
        leader: Double,
        leaderId: String,
        top3: Double,
        furthest: String,
        tracked: Int? = nil
    ) {
        self.date = date
        self.leader = leader
        self.leaderId = leaderId
        self.top3 = top3
        self.furthest = furthest
        self.tracked = tracked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = LenientDecoding.optionalString(from: container, forKey: .date) ?? ""
        leader = LenientDecoding.optionalDouble(from: container, forKey: .leader) ?? 0
        leaderId = LenientDecoding.optionalString(from: container, forKey: .leaderId) ?? ""
        top3 = LenientDecoding.optionalDouble(from: container, forKey: .top3) ?? 0
        furthest = LenientDecoding.optionalString(from: container, forKey: .furthest) ?? "groundwork"
        tracked = LenientDecoding.optionalInt(from: container, forKey: .tracked)
    }
}

public enum PortWatchURLs {
    public static let siteRoot = URL(string: "https://portwatch-vi.xyz")!
    public static let trackerJSON = URL(string: "https://portwatch-vi.xyz/data/tracker.json")!
    public static let scoringJS = URL(string: "https://portwatch-vi.xyz/assets/js/scoring.js")!
}