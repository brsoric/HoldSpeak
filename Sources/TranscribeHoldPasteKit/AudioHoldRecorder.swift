import AVFoundation
import AudioToolbox
import Foundation
import os

private let logger = Logger(subsystem: "com.holdspeak.app", category: "AudioRecorder")

public final class AudioHoldRecorder {
    public enum RecorderError: Error {
        case alreadyRecording
        case notRecording
        case recorderInitFailed
        case startFailed
        case stopFailed
    }

    private var recorder: AVAudioRecorder?
    private var currentURL: URL?
    private var meterTimer: Timer?

    public var amplitudeHandler: ((Float) -> Void)?

    public init() {}

    deinit {
        stopMeterPolling()
        recorder?.stop()
    }

    public var isRecording: Bool { recorder?.isRecording ?? false }

    public func start() throws {
        guard recorder == nil else { throw RecorderError.alreadyRecording }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcribe-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder: AVAudioRecorder
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
        } catch {
            logger.error("AVAudioRecorder init failed: \(error.localizedDescription, privacy: .public)")
            throw RecorderError.recorderInitFailed
        }

        recorder.isMeteringEnabled = true

        guard recorder.record() else {
            throw RecorderError.startFailed
        }

        self.currentURL = url
        self.recorder = recorder
        startMeterPolling()
    }

    public func stop() throws -> URL {
        guard let recorder else { throw RecorderError.notRecording }
        guard let url = currentURL else { throw RecorderError.stopFailed }

        stopMeterPolling()
        recorder.stop()
        self.recorder = nil
        self.currentURL = nil

        return url
    }

    private func startMeterPolling() {
        let interval: TimeInterval = 1.0 / 24.0
        meterTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder, recorder.isRecording else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let normalized = max(0, min(1, (power + 50) / 50))
            self.amplitudeHandler?(normalized)
        }
        RunLoop.main.add(meterTimer!, forMode: .common)
    }

    private func stopMeterPolling() {
        meterTimer?.invalidate()
        meterTimer = nil
    }
}
