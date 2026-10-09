import Foundation
struct LetterCandidate: Sendable {
 let letter: String
 let probability: Double
 let observedAt: Date
 func isUsable(now: Date) -> Bool {
  letter.count == 1 && "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(letter) && probability.isFinite && probability >= 0.8 && probability <= 1 && now.timeIntervalSince(observedAt) >= 0 && now.timeIntervalSince(observedAt) <= 1
 }
}
struct MessageDraft {
 var text = ""
 mutating func add(_ candidate: LetterCandidate?, now: Date) {
  guard let candidate, candidate.isUsable(now: now) else { return }
  text += candidate.letter
 }
 mutating func addSpace() { if !text.isEmpty && !text.hasSuffix(" ") { text += " " } }
 mutating func deleteLast() { if !text.isEmpty { text.removeLast() } }
 mutating func clear() { text = "" }
}
struct AudioActivity {
 private(set) var isListening = false
 private(set) var isSpeaking = false
 mutating func startListening() { isListening = true; isSpeaking = false }
 mutating func startSpeaking() { isListening = false; isSpeaking = true }
 mutating func stop() { isListening = false; isSpeaking = false }
}
