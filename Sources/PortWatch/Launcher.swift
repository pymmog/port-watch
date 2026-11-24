import AppKit
import Foundation

@main
enum Launcher {
    static func main() {
        if let outputDirectory = SnapshotCommandLine.outputDirectory() {
            let status = SnapshotRunner.runSynchronously(outputDirectory: outputDirectory)
            exit(status)
        }
        PortWatchApp.main()
    }
}