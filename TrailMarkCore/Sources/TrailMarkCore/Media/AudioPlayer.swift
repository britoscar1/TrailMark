import Foundation
import Combine
import AVFoundation

@MainActor
@Observable

public final class AudioPlayer: NSObject {
    public private(set) var isPlaying: Bool = false
    private var player: AVAudioPlayer?
    public override init() {super.init() }
    
    public func play(url: URL) {
        do{
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.play()
            self.player = player
            self.isPlaying = true
        } catch {
            isPlaying = false
        }
    }
    
    public func stop() {
        player?.stop()
        self.player = nil
        self.isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false}
    }
}
