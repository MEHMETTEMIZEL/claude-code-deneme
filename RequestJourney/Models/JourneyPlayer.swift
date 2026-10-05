import SwiftUI
import Observation

/// Yolculuğu adım adım oynatan, durdurulabilen oynatıcı.
@MainActor
@Observable
final class JourneyPlayer {
    let steps: [JourneyStep] = JourneyData.steps
    var index = 0
    var isPlaying = false
    /// 1 = adım başına 5 saniye.
    var speed: Double = 1

    @ObservationIgnored private var playTask: Task<Void, Never>?

    private let stepAnimation = Animation.spring(response: 0.55, dampingFraction: 0.82)

    var current: JourneyStep { steps[index] }
    var isFirst: Bool { index == 0 }
    var isLast: Bool { index == steps.count - 1 }
    var progress: Double { Double(index + 1) / Double(steps.count) }

    func next() {
        guard !isLast else { pause(); return }
        withAnimation(stepAnimation) { index += 1 }
    }

    func previous() {
        guard !isFirst else { return }
        withAnimation(stepAnimation) { index -= 1 }
    }

    func jump(to newIndex: Int) {
        pause()
        withAnimation(stepAnimation) { index = min(max(newIndex, 0), steps.count - 1) }
    }

    /// Katmana dokununca o katmanın (tercihen aynı yöndeki) ilk adımına atlar.
    func jump(toLayer layer: Layer) {
        let sameDirection = steps.firstIndex { $0.layer == layer && $0.direction == current.direction }
        if let target = sameDirection ?? steps.firstIndex(where: { $0.layer == layer }) {
            jump(to: target)
        }
    }

    func togglePlay() {
        isPlaying ? pause() : play()
    }

    func play() {
        if isLast { withAnimation(stepAnimation) { index = 0 } }
        isPlaying = true
        playTask?.cancel()
        playTask = Task { [weak self] in
            while !Task.isCancelled {
                let delay = 5.0 / (self?.speed ?? 1)
                try? await Task.sleep(for: .seconds(delay))
                guard let self, !Task.isCancelled, self.isPlaying else { return }
                if self.isLast {
                    self.pause()
                    return
                }
                self.next()
            }
        }
    }

    func pause() {
        isPlaying = false
        playTask?.cancel()
        playTask = nil
    }

    func reset() {
        pause()
        withAnimation(stepAnimation) { index = 0 }
    }
}
