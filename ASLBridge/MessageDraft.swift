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

// Ten recent predictions, including uncertain samples, prevent transition frames from winning.
struct LetterStabilityFilter {
 private var samples: [(date: Date, letter: String?)] = []
 mutating func reset() { samples.removeAll() }
 mutating func observe(_ candidate: LetterCandidate?, now: Date) -> LetterCandidate? {
  guard let candidate, now.timeIntervalSince(candidate.observedAt) >= 0,
        now.timeIntervalSince(candidate.observedAt) <= 0.5 else { reset(); return nil }
  if let last = samples.last, now.timeIntervalSince(last.date) > 0.5 || now <= last.date { reset() }
  samples.removeAll { now.timeIntervalSince($0.date) > 2 }
  let confident = candidate.isUsable(now: now) && candidate.probability >= 0.85
  samples.append((now, confident ? candidate.letter : nil))
  if samples.count > 10 { samples.removeFirst(samples.count - 10) }
  guard confident, samples.count == 10,
        samples.filter({ $0.letter == candidate.letter }).count >= 8 else { return nil }
  return candidate
 }
}
