import Foundation
import CoreLocation

public enum MemoKind: String, Codable, Sendable, CaseIterable {
    case audio
    case video
    
    public var symbolName: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }
    public var displayName: String {
        switch self {
        case .audio: return "Audio Memo"
        case .video: return "Video Memo"
        }
    }
}

public struct MediaMemo: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var kind: MemoKind
    // filename relative to the media directory e.g A1B2-file.m4a
    public var fileName: String
    public var createdAt: Date
    public var duration: TimeInterval
    public var title: String
    
    //geotag data
    public var latitude: Double?
    public var longitude: Double?
    
    
    public init(
        id: UUID = UUID(),
        kind: MemoKind,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title.isEmpty ? Self.defaultTitle(for: kind, at: createdAt) : title
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public mutating func setCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        latitude = coordinate?.latitude
        longitude = coordinate?.longitude
    }
    public var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0.00"
    }
    // When title is not specified this function will create
    // a default title like audio memo-06-27-2026 9:39 AM
    private static func defaultTitle(for kind: MemoKind, at date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "\(kind.displayName) - \(df.string(from: date))"
    }
}
