import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
 @Published var transcript = ""
 @Published private(set) var status = "Tap Listen to see a spoken reply."
 @Published private(set) var activity = AudioActivity()
 private let engine = AVAudioEngine()
 private let synthesizer = AVSpeechSynthesizer()
 private var recognitionTask: SFSpeechRecognitionTask?
 private var request: SFSpeechAudioBufferRecognitionRequest?
 private var hasTap = false
 private var generation = UUID()
 override init() { super.init(); synthesizer.delegate = self }
 func startListening() {
  stopAll()
  let token = generation
  status = "Checking microphone and speech access…"
  Task { [self] in
   let authorization = await withCheckedContinuation { continuation in
    SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
   }
   guard generation == token else { return }
   guard authorization == .authorized else { status = "Speech access denied. Type the reply instead."; return }
   let micAllowed = await AVAudioApplication.requestRecordPermission()
   guard generation == token else { return }
   guard micAllowed else { status = "Microphone access denied. Type the reply instead."; return }
   guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
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
    transcript = ""
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in request.append(buffer) }
    hasTap = true
    recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
     let text = result?.bestTranscription.formattedString
     let isFinal = result?.isFinal ?? false
     Task { @MainActor [weak self] in
      guard let self, self.generation == token else { return }
      if let text { self.transcript = text }
      if error != nil || isFinal {
       self.stopListening()
       self.status = error == nil ? "Reply captured. Tap Listen for another reply." : "Listening ended. Retry, or type the reply."
      }
     }
    }
    engine.prepare(); try engine.start()
    activity.startListening(); status = "Listening… speak your reply."
   } catch {
    stopListening(); status = "Could not start microphone. Retry, or type the reply."
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
  guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
  stopAll()
  do {
   let session = AVAudioSession.sharedInstance()
   try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
   try session.setActive(true)
   let utterance = AVSpeechUtterance(string: text)
   utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
   utterance.rate = AVSpeechUtteranceDefaultSpeechRate
   activity.startSpeaking(); status = "Speaking your message…"
   synthesizer.speak(utterance)
  } catch { status = "Could not play speech. Your message is still visible." }
 }
 func stopAll() {
  stopListening()
  synthesizer.stopSpeaking(at: .immediate)
  activity.stop()
 }
 nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
  Task { @MainActor [weak self] in
   guard let self, self.activity.isSpeaking, !self.synthesizer.isSpeaking else { return }
   self.activity.stop(); self.status = "Message spoken."
   try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
 }
 private enum AudioFailure: Error { case noInput }
}
