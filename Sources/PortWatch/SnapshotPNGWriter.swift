import AppKit
import CoreGraphics
import Foundation

enum SnapshotPNGWriter {
    static func write(cgImage: CGImage, to url: URL) throws {
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngEncodingFailed
        }
        try data.write(to: url, options: .atomic)
    }
}

enum SnapshotError: Error, LocalizedError {
    case pngEncodingFailed
    case renderFailed(String)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .pngEncodingFailed:
            return "Could not encode PNG."
        case .renderFailed(let label):
            return "Could not render \(label)."
        case .timedOut:
            return "Snapshot timed out."
        }
    }
}