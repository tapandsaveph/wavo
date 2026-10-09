import Testing
@testable import BridgeCore
@Test func matchesOnlySupportedCompleteUtterances() {
 #expect(VocabularyCatalog.matching(" Yes! ")?.id == "yes")
 #expect(VocabularyCatalog.matching("Thank you.")?.id == "thank-you")
 #expect(VocabularyCatalog.matching("Yesterday was nice") == nil)
 #expect(VocabularyCatalog.matching("No, thank you") == nil)
 #expect(VocabularyCatalog.matching("") == nil)
}
@Test func searchableCatalogKeepsRecognitionClaimsHonest() {
 #expect(VocabularyCatalog.filtered(by: "thanks").map(\.id) == ["thank-you"])
 #expect(VocabularyCatalog.words.allSatisfy { !$0.cameraRecognitionAvailable })
 #expect(Set(VocabularyCatalog.words.map(\.id)).count == VocabularyCatalog.words.count)
}
