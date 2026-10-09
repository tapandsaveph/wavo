import Foundation
import Speech
import AVFoundation
import Combine
import OSLog

@MainActor
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
 @Published var transcript = ""
 @Published private(set) var status = "Tap Listen to see a spoken reply."
 @Published private(set) var activity = AudioActivity()
 private let engine = AVAudioEngine()
 private let synthesizer = AVSpeechSynthesizer()
 private let offlineVoice = OfflineVoice()
 private var synthesisTask: Task<Void, Never>?
 private var player: AVAudioPlayer?
 private var speechFile: URL?
 private var recognitionTask: SFSpeechRecognitionTask?
 private var request: SFSpeechAudioBufferRecognitionRequest?
 private var hasTap = false
 @Published private(set) var continuousListening = false
 private var restartTask: Task<Void, Never>?
 private let logger = Logger(subsystem: "com.nehroranay.aslbridge", category: "captions")
 private var consecutiveFailures = 0
 private var generation = UUID()
 override init() { super.init(); synthesizer.delegate = self }
 func startContinuousListening() {
  continuousListening = true
  consecutiveFailures = 0
  startListening()
 }
 func startListening() {
  let keepListening = continuousListening
  stopAll()
  continuousListening = keepListening
  let token = generation
  status = "Checking microphone and speech access…"
  Task { [self] in
   let authorization = await withCheckedContinuation { continuation in
    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
   }
   guard generation == token else { return }
   guard authorization == .authorized else { continuousListening = false; status = "Speech access denied. Type the reply instead."; return }
   let micAllowed = await AVAudioApplication.requestRecordPermission()
   guard generation == token else { return }
   guard micAllowed else { continuousListening = false; status = "Microphone access denied. Type the reply instead."; return }
   guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
    continuousListening = false
    status = "Offline English captions are unavailable on this device. Type the reply instead."; return
   }
   do {
    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
    try audioSession.setActive(true)
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0 && format.channelCount > 0 else { throw AudioFailure.noInput }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    self.request = request
    let previousTranscript = continuousListening ? transcript : ""
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
    hasTap = true
    recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
     let text = result?.bestTranscription.formattedString
     let isFinal = result?.isFinal ?? false
     Task { @MainActor [weak self] in
      guard let self, self.generation == token else { return }
      if let text { self.transcript = previousTranscript.isEmpty ? text : previousTranscript + "\n" + text; self.consecutiveFailures = 0 }
      if error != nil || isFinal {
       self.logger.info("Recognition ended; final=\(isFinal), error=\((error as NSError?)?.code ?? 0), continuous=\(self.continuousListening)")
       self.stopListening()
       if self.continuousListening {
        if error != nil { self.consecutiveFailures += 1 }
        self.scheduleRestart()
       } else {
        self.status = error == nil ? "Reply captured." : "Listening ended. Retry, or type the reply."
       }
      }
     }
    }
    engine.prepare(); try engine.start()
    logger.info("Microphone engine started for captions")
    activity.startListening(); status = "Listening… speak your reply."
   } catch {
    continuousListening = false; stopListening(); status = "Could not start microphone. Retry, or type the reply."
   }
  }
 }
 func stopListening() {
  generation = UUID()
  engine.stop()
  if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
  request?.endAudio(); recognitionTask?.cancel()
  request = nil; recognitionTask = nil
  activity.stop()
  try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  status = "Listening stopped. Your captions stay visible."
 }
 func speak(_ text: String) {
  let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !message.isEmpty else { return }
  let keepListening = continuousListening
  stopAll()
  continuousListening = keepListening
  let token = generation
  activity.startSpeaking(); status = "Preparing offline voice…"
  synthesisTask = Task { [weak self] in
   guard let self else { return }
   do {
    let url = try await self.offlineVoice.generate(message)
    guard !Task.isCancelled, self.generation == token else {
     try? FileManager.default.removeItem(at: url); return
    }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    try session.setActive(true)
    self.speechFile = url
    let player = try AVAudioPlayer(contentsOf: url)
    self.player = player; player.delegate = self
    guard player.play() else { throw AudioFailure.noInput }
    self.status = "Speaking with offline neural voice…"
   } catch {
    guard !Task.isCancelled, self.generation == token else { return }
    self.logger.error("Offline voice failed; using system voice")
    self.speakWithSystemVoice(message)
   }
  }
 }
 private func speakWithSystemVoice(_ text: String) {
  guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
  let keepListening = continuousListening
  stopAll()
  continuousListening = keepListening
  do {
   let session = AVAudioSession.sharedInstance()
   try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
   try session.setActive(true)
   let utterance = AVSpeechUtterance(string: text)
   // Resolve each time so newly downloaded system voices are picked up immediately.
   let voice = preferredVoice()
   utterance.voice = voice
   logger.info("Speech voice: \(voice?.name ?? "Default", privacy: .public), quality: \(voice?.quality.rawValue ?? 0)")
   utterance.rate = AVSpeechUtteranceDefaultSpeechRate
   activity.startSpeaking(); status = "Speaking with \(voice?.name ?? "English")…"
   synthesizer.speak(utterance)
  } catch { status = "Could not play speech. Your message is still visible."; if continuousListening { scheduleRestart() } }
 }
 func stopAll() {
  synthesisTask?.cancel(); synthesisTask = nil
  player?.stop(); player = nil
  if let speechFile { try? FileManager.default.removeItem(at: speechFile) }; speechFile = nil
  continuousListening = false
  restartTask?.cancel(); restartTask = nil
  stopListening()
  synthesizer.stopSpeaking(at: .immediate)
  activity.stop()
 }
 nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
  Task { @MainActor [weak self] in
   guard let self, self.activity.isSpeaking, !self.synthesizer.isSpeaking else { return }
   self.activity.stop(); self.status = "Message spoken."
   try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
   if self.continuousListening { self.scheduleRestart() }
  }
 }
 private func scheduleRestart() {
  restartTask?.cancel()
  status = "Resuming live captions…"
  restartTask = Task { [weak self] in
   let delay = min(5, max(0.7, Double(self?.consecutiveFailures ?? 0)))
   try? await Task.sleep(for: .seconds(delay))
   guard !Task.isCancelled, let self, self.continuousListening, !self.activity.isSpeaking else { return }
   self.restartTask = nil
   self.startListening()
  }
 }
 func stopSpeakingAndResume() {
  let keepListening = continuousListening
  stopAll()
  continuousListening = keepListening
  if keepListening { scheduleRestart() }
 }
 nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
  Task { @MainActor [weak self] in
   guard let self, self.player === player else { return }
   self.player = nil
   if let file = self.speechFile { try? FileManager.default.removeItem(at: file) }; self.speechFile = nil
   self.activity.stop(); self.status = flag ? "Message spoken." : "Speech playback interrupted."
   try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
   if self.continuousListening { self.scheduleRestart() }
  }
 }
 private func preferredVoice() -> AVSpeechSynthesisVoice? {
  let english = AVSpeechSynthesisVoice.speechVoices().filter {
   $0.language == "en-US" && !$0.identifier.lowercased().contains("eloquence")
  }
  return english.sorted { lhs, rhs in
   if lhs.quality != rhs.quality { return lhs.quality.rawValue > rhs.quality.rawValue }
   let preferredNames = ["Ava", "Samantha", "Allison"]
   let left = preferredNames.firstIndex(of: lhs.name) ?? preferredNames.count
   let right = preferredNames.firstIndex(of: rhs.name) ?? preferredNames.count
   if left != right { return left < right }
   return lhs.identifier < rhs.identifier
  }.first ?? AVSpeechSynthesisVoice(language: "en-US")
 }
 private enum AudioFailure: Error { case noInput }
}
