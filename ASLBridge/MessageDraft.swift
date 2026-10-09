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

// Emit once per steady sign; brief detection flicker does not rearm a held letter.
struct LetterStabilityFilter {
 private var held: String?
 private var heldSince: Date?
 private var lastObservation: Date?
 private var captured: String?
 private var missingSince: Date?
 func alreadyCaptured(_ letter: String) -> Bool { captured == letter }
 mutating func reset() { self = LetterStabilityFilter() }
 mutating func observe(_ candidate: LetterCandidate?, now: Date) -> LetterCandidate? {
  if let lastObservation, now <= lastObservation || now.timeIntervalSince(lastObservation) > 0.5 {
   held = nil; heldSince = nil
  }
  lastObservation = now
  guard let candidate else {
   held = nil; heldSince = nil
   if missingSince == nil { missingSince = now }
   if let missingSince, now.timeIntervalSince(missingSince) >= 0.3 { captured = nil }
   return nil
  }
  missingSince = nil
  guard candidate.isUsable(now: now), candidate.probability >= 0.85,
        now.timeIntervalSince(candidate.observedAt) <= 0.5 else {
   held = nil; heldSince = nil; return nil
  }
  if held != candidate.letter { held = candidate.letter; heldSince = now }
  guard let heldSince, now.timeIntervalSince(heldSince) >= 0.25,
        captured != candidate.letter else { return nil }
  captured = candidate.letter
  return candidate
 }
}

// One draft entry per gesture; two confident Other windows permit a new Hello.
struct HelloCaptureGate {
 private var captured = false
 private var otherWindows = 0
 mutating func reset() { captured = false; otherWindows = 0 }
 mutating func observe(label: String, confidence: Double) -> Bool {
  guard confidence.isFinite, confidence >= 0.9 else { otherWindows = 0; return false }
  if label == "Other" {
   otherWindows += 1
   if otherWindows >= 2 { captured = false }
   return false
  }
  otherWindows = 0
  guard ["Hello", "ThankYou"].contains(label), !captured else { return false }
  captured = true
  return true
 }
}

struct HelloWindowCheck {
 static func canPredict(_ tracked: [Bool]) -> Bool {
  tracked.count == 15 && tracked.last == true && tracked.filter { $0 }.count >= 9
 }
}

enum TrainingClipLabel: String, CaseIterable {
 case thankYou = "Thank you", hello = "Hello", ordinary = "Ordinary movement"
 var folder: String {
  switch self { case .thankYou: "ThankYou"; case .hello: "Hello"; case .ordinary: "Other" }
 }
}
enum TrainingClipSplit: String, CaseIterable {
 case training = "Training", testing = "Testing"
 var folder: String { self == .training ? "train" : "test" }
}
