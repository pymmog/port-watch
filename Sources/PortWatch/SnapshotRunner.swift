import AppKit
import Foundation

enum SnapshotRunner {
    private static let timeoutSeconds: TimeInterval = 60

    static func runSynchronously(outputDirectory: URL) -> Int32 {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        var exitCode: Int32 = 1
        var finished = false
        let started = Date()

        Task { @MainActor in
            exitCode = await runWithTimeout(outputDirectory: outputDirectory)
            finished = true
        }

        while !finished {
            if Date().timeIntervalSince(started) > timeoutSeconds {
                fputs("PortWatch snapshot timed out after \(Int(timeoutSeconds)) seconds\n", stderr)
                return 1
            }
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        return exitCode
    }

    @MainActor
    private static func runWithTimeout(outputDirectory: URL) async -> Int32 {
        await withTaskGroup(of: Int32.self) { group in
            group.addTask {
                do {
                    try await HeadlessSnapshot.run(outputDirectory: outputDirectory)
                    for name in HeadlessSnapshot.outputFiles {
                        print(outputDirectory.appendingPathComponent(name).path)
                    }
                    return 0
                } catch {
                    fputs("PortWatch snapshot failed: \(error.localizedDescription)\n", stderr)
                    return 1
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                return -1
            }

            let first = await group.next() ?? 1
            group.cancelAll()

            if first == -1 {
                fputs("PortWatch snapshot timed out after \(Int(timeoutSeconds)) seconds\n", stderr)
                return 1
            }
            return first
        }
    }
}