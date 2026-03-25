import Foundation
import Combine

final class PulseViewModel: ObservableObject {
    @Published var stats = SystemStats.zero

    private var sampleTimer: Timer?

    init() {
        setupStatsListener()
        startSampleRecording()
    }

    private func setupStatsListener() {
        SystemMonitor.shared.onStatsUpdate = { [weak self] newStats in
            DispatchQueue.main.async {
                self?.stats = newStats
            }
        }
    }

    private func startSampleRecording() {
        // Record to SQLite every 60 seconds
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            SettingsStore.shared.recordSample(self.stats)
        }
    }

    deinit {
        sampleTimer?.invalidate()
    }
}
