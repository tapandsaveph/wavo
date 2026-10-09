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
@Test func stabilityRequiresFullWindowAndEightConfidentMatches() {
 var filter = LetterStabilityFilter()
 let start = Date()
 func sample(_ letter: String, _ score: Double, _ index: Int) -> LetterCandidate {
  LetterCandidate(letter: letter, probability: score, observedAt: start.addingTimeInterval(Double(index) * 0.15))
 }
 for index in 0..<9 {
  let value = sample("A", index < 2 ? 0.7 : 0.95, index)
  #expect(filter.observe(value, now: value.observedAt) == nil)
 }
 let last = sample("A", 0.95, 9)
 #expect(filter.observe(last, now: last.observedAt)?.letter == "A")
 let transition = sample("S", 0.95, 10)
 #expect(filter.observe(transition, now: transition.observedAt) == nil)
}
@Test func stabilityResetsForMissingHandAndTimeGaps() {
 var filter = LetterStabilityFilter()
 let start = Date()
 for index in 0..<10 {
  let now = start.addingTimeInterval(Double(index) * 0.15)
  _ = filter.observe(LetterCandidate(letter: "B", probability: 0.99, observedAt: now), now: now)
 }
 #expect(filter.observe(nil, now: start.addingTimeInterval(1.5)) == nil)
 let now = start.addingTimeInterval(1.65)
 #expect(filter.observe(LetterCandidate(letter: "B", probability: 0.99, observedAt: now), now: now) == nil)
 let later = start.addingTimeInterval(5)
 #expect(filter.observe(LetterCandidate(letter: "B", probability: 0.99, observedAt: later), now: later) == nil)
 #expect(filter.observe(LetterCandidate(letter: "B", probability: 0.99, observedAt: now), now: later) == nil)
}
@Test func stabilityRejectsSplitVotesAndUncertainCurrentFrame() {
 var filter = LetterStabilityFilter()
 let start = Date()
 for index in 0..<10 {
  let now = start.addingTimeInterval(Double(index) * 0.15)
  let candidate = LetterCandidate(letter: index % 2 == 0 ? "A" : "S", probability: 0.99, observedAt: now)
  #expect(filter.observe(candidate, now: now) == nil)
 }
 filter.reset()
 for index in 0..<10 {
  let now = start.addingTimeInterval(Double(index) * 0.15)
  _ = filter.observe(LetterCandidate(letter: "A", probability: 0.99, observedAt: now), now: now)
 }
 let now = start.addingTimeInterval(1.5)
 #expect(filter.observe(LetterCandidate(letter: "A", probability: 0.84, observedAt: now), now: now) == nil)
}
