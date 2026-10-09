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
