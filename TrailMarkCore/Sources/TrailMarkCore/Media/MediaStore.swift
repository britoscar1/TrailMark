import Foundation
import AVFoundation
import Combine
import CoreLocation
import Observation

#if canImport(UIKit)
import UIKit
#endif
 
@MainActor
@Observable
public final class MediaStore {
    public private(set) var memos: [MediaMemo] = []
    
    private let fileManager = FileManager.default
    private let indexFileName = "memos.json"
    
    public init(){
        loadIndex()
    }
    public var mediaDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Media", isDirectory: true)
        
        if !fileManager.fileExists(atPath: dir.path){
            try? fileManager.createDirectory(atPath: dir.path, withIntermediateDirectories: true)
        }
        
        return dir
    }
    
    private var indexURL: URL {
        mediaDirectory.appendingPathComponent(indexFileName)
    }
    public func url(for memo: MediaMemo) -> URL {
        mediaDirectory.appendingPathComponent(memo.fileName)
    }
    
    @discardableResult
    public func add(
        kind: MemoKind,
        movingFileFrom sourceURL: URL,
        duration: TimeInterval,
        title: String = "",
        coordinate: CLLocationCoordinate2D? = nil
    ) throws -> MediaMemo {
        let id = UUID()
        let ext = sourceURL.pathExtension.isEmpty ? (kind == .audio ? "m4a" : "mov") : sourceURL.pathExtension
        let fileName = "\(id.uuidString).\(ext)"
        let destination = mediaDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destination.path){
            try fileManager.removeItem(at: destination)
        }
        
        try fileManager.moveItem(at: sourceURL, to: destination)
        
        var memo = MediaMemo(
            id: id,
            kind: kind,
            fileName: fileName,
            duration: duration,
            title: title
        )
        memo.setCoordinate(coordinate)
        
        memos.insert(memo, at: 0)
        persistentIndex()
        return memo
    }

    public func delete(_ memo: MediaMemo) {
        let fileURL = url(for: memo)
        try? fileManager.removeItem(at: fileURL)
        memos.removeAll { $0.id == memo.id }
        persistentIndex()
    }

    public func delete(at offsets: IndexSet) {
        offsets.map { memos[$0] }.forEach(delete)
    }

    #if canImport(UIKit) && !os(watchOS)
    public func thumbnail(for memo: MediaMemo) async -> UIImage? {
        guard memo.kind == .video else { return nil }
        let asset = AVURLAsset(url: url(for: memo))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        do {
            let cgImage = try await generator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    #endif

    private func persistentIndex(){
        guard let data = try? JSONEncoder().encode(memos) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL) else {return}
        
        let decoded = (try? JSONDecoder().decode([MediaMemo].self, from: data)) ?? []
        
        memos = decoded.sorted {$0.createdAt > $1.createdAt}
    }
    
}
