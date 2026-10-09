import Testing
@testable import BridgeCore
@Test func helloRequiresConfidenceAndRearmsAfterOther() {
 var gate = HelloCaptureGate()
 let result1 = gate.observe(label: "Hello", confidence: 0.6)
 #expect(!result1)
 let result2 = gate.observe(label: "Hello", confidence: 0.95)
 #expect(result2)
 let result3 = gate.observe(label: "Hello", confidence: 0.99)
 #expect(!result3)
 let result4 = gate.observe(label: "Other", confidence: 0.95)
 #expect(!result4)
 let result5 = gate.observe(label: "Hello", confidence: 0.99)
 #expect(!result5)
 let result6 = gate.observe(label: "Other", confidence: 0.95)
 #expect(!result6)
 let result7 = gate.observe(label: "Other", confidence: 0.95)
 #expect(!result7)
 let result8 = gate.observe(label: "Hello", confidence: 0.95)
 #expect(result8)
}
@Test func helloWindowAllowsBriefTrackingGapsButRejectsAbsentHands() {
 #expect(HelloWindowCheck.canPredict(Array(repeating: true, count: 11) + [false, false, false, true]))
 #expect(!HelloWindowCheck.canPredict(Array(repeating: false, count: 15)))
 #expect(!HelloWindowCheck.canPredict(Array(repeating: true, count: 14)))
 #expect(!HelloWindowCheck.canPredict(Array(repeating: true, count: 14) + [false]))
 #expect(!HelloWindowCheck.canPredict(Array(repeating: false, count: 7) + Array(repeating: true, count: 8)))
}
@Test func capturesThankYouOncePerGesture() {
 var gate = HelloCaptureGate()
 let first = gate.observe(label: "ThankYou", confidence: 0.99)
 #expect(first)
 let repeated = gate.observe(label: "ThankYou", confidence: 0.99)
 #expect(!repeated)
 let transition = gate.observe(label: "Hello", confidence: 0.99)
 #expect(!transition)
 gate.reset()
 let next = gate.observe(label: "Hello", confidence: 0.99)
 #expect(next)
}
@Test func recordingsKeepLabelsAndTestSplitSeparate() {
 #expect(TrainingClipLabel.thankYou.folder == "ThankYou")
 #expect(TrainingClipLabel.ordinary.folder == "Other")
 #expect(TrainingClipSplit.testing.folder != TrainingClipSplit.training.folder)
}
