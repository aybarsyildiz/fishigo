import AVFoundation

/// §7 sound layer — the signature sounds, each the twin of a FeelKit haptic.
///
/// Design choices (§7 "respect silent switch, duck under music"):
/// - `.ambient` category → the hardware mute switch silences everything, which
///   is the stronger expectation for an app used quietly on the water. True
///   ducking under music would require `.playback` and would DEFEAT the mute
///   switch, so we choose the switch and mix instead. Flagged tradeoff.
/// - All sounds optional via `sesAcik` (default on). Placeholder WAVs today;
///   TODO(sound): swap for recorded foley before launch.
@MainActor
final class Ses {
    static let shared = Ses()

    private var players: [String: AVAudioPlayer] = [:]
    private var configured = false

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: "sesAcik") as? Bool ?? true
    }

    private init() {}

    private func ensureSession() {
        guard !configured else { return }
        configured = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func player(_ name: String) -> AVAudioPlayer? {
        if let existing = players[name] { return existing }
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        players[name] = player
        return player
    }

    private func play(_ name: String, volume: Float = 1) {
        guard enabled else { return }
        ensureSession()
        guard let player = player(name) else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    // §7 signature sounds — called from FeelKit alongside their haptic twins.
    func tik() { play("tik", volume: 0.5) }
    func damga() { play("damga", volume: 0.9) }
    func yeniTur() { play("yeni-tur", volume: 0.8) }
}
