import Foundation

enum SnapshotCommandLine {
    static var wantsSnapshot: Bool {
        CommandLine.arguments.contains("--snapshot")
    }

    static func outputDirectory(from arguments: [String] = CommandLine.arguments) -> URL? {
        guard let index = arguments.firstIndex(of: "--snapshot"), index + 1 < arguments.count else {
            return nil
        }
        return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    }
}