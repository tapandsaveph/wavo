import Testing
import Foundation
@testable import BridgeCore
@Test func repeatedLettersAndEdits() {
 var draft = MessageDraft()
 let now = Date()
 let letter = LetterCandidate(letter: "S", probability: 0.95, observedAt: now)
 draft.add(letter, now: now); draft.add(letter, now: now)
 #expect(draft.text == "SS")
 draft.addSpace(); #expect(draft.text == "SS ")
 draft.deleteLast(); draft.clear(); draft.deleteLast()
 #expect(draft.text.isEmpty)
}
@Test func rejectsUncertainStaleAndInvalidCandidates() {
 var draft = MessageDraft()
 let now = Date()
 draft.add(nil, now: now)
 draft.add(LetterCandidate(letter: "S", probability: 0.4, observedAt: now), now: now)
 draft.add(LetterCandidate(letter: "S", probability: 0.99, observedAt: now.addingTimeInterval(-2)), now: now)
 draft.add(LetterCandidate(letter: "background", probability: 0.99, observedAt: now), now: now)
 #expect(draft.text.isEmpty)
}
@Test func speechAndListeningAreExclusive() {
 var state = AudioActivity()
 state.startListening(); #expect(state.isListening)
 state.startSpeaking(); #expect(!state.isListening && state.isSpeaking)
 state.stop(); #expect(!state.isListening && !state.isSpeaking)
}
@Test func automaticCaptureRequiresHoldAndDoesNotRepeat() {
 var filter = LetterStabilityFilter()
 let start = Date()
 for index in 0..<4 {
  let now = start.addingTimeInterval(Double(index) * 0.10)
  let result = filter.observe(LetterCandidate(letter: "A", probability: 0.95, observedAt: now), now: now)
  #expect((result != nil) == (index == 3))
 }
 for index in 4..<10 {
  let now = start.addingTimeInterval(Double(index) * 0.10)
  #expect(filter.observe(LetterCandidate(letter: "A", probability: 0.95, observedAt: now), now: now) == nil)
 }
}
@Test func automaticCaptureRearmsAfterSustainedHandAbsence() {
 var filter = LetterStabilityFilter()
 let start = Date()
 func hold(_ letter: String, offset: Double) -> String? {
  var result: String?
  for index in 0..<4 {
   let now = start.addingTimeInterval(offset + Double(index) * 0.10)
   result = filter.observe(LetterCandidate(letter: letter, probability: 0.95, observedAt: now), now: now)?.letter
  }
  return result
 }
 #expect(hold("A", offset: 0) == "A")
 #expect(hold("B", offset: 0.4) == "B")
 _ = filter.observe(nil, now: start.addingTimeInterval(1.2))
 _ = filter.observe(nil, now: start.addingTimeInterval(1.6))
 #expect(hold("B", offset: 1.76) == "B")
}
@Test func automaticCaptureRejectsFlickerUncertainAndStaleSamples() {
 var filter = LetterStabilityFilter()
 let start = Date()
 for index in 0..<12 {
  let now = start.addingTimeInterval(Double(index) * 0.10)
  #expect(filter.observe(LetterCandidate(letter: index % 2 == 0 ? "A" : "S", probability: 0.99, observedAt: now), now: now) == nil)
 }
 let now = start.addingTimeInterval(2)
 #expect(filter.observe(LetterCandidate(letter: "S", probability: 0.84, observedAt: now), now: now) == nil)
 #expect(filter.observe(LetterCandidate(letter: "S", probability: 0.99, observedAt: start), now: now) == nil)
}

@Test func fastCaptureWaitsQuarterSecond() {
 var filter = LetterStabilityFilter()
 let start = Date()
 for offset in [0.0, 0.08, 0.16, 0.24] {
  let now = start.addingTimeInterval(offset)
  #expect(filter.observe(LetterCandidate(letter: "A", probability: 0.95, observedAt: now), now: now) == nil)
 }
 let now = start.addingTimeInterval(0.32)
 #expect(filter.observe(LetterCandidate(letter: "A", probability: 0.95, observedAt: now), now: now)?.letter == "A")
}
