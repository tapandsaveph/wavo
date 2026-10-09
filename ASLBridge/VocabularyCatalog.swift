import Foundation
struct VocabularyEntry: Identifiable, Sendable {
 let id: String
 let title: String
 let aliases: [String]
 let referenceURL: URL
 // A reference does not imply that the camera has a trained model for the sign.
 let cameraRecognitionAvailable = false
}
enum VocabularyCatalog {
 static let alphabet = VocabularyEntry(id: "alphabet", title: "ASL Alphabet", aliases: ["fingerspelling"], referenceURL: URL(string: "https://www.lifeprint.com/asl101/fingerspelling/fingerspelling.htm")!)
 static let words: [VocabularyEntry] = [
  .init(id: "hello", title: "Hello", aliases: ["hi"], referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/h/hello.htm")!),
  .init(id: "name", title: "Name", aliases: [], referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/n/name.htm")!),
  .init(id: "thank-you", title: "Thank you", aliases: ["thanks"], referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/t/thankyou.htm")!),
  .init(id: "yes", title: "Yes", aliases: [], referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/y/yes.htm")!),
  .init(id: "no", title: "No", aliases: [], referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/n/no.htm")!)
 ]
 static func matching(_ text: String) -> VocabularyEntry? {
  let text = normalize(text)
  guard !text.isEmpty else { return nil }
  return words.first { normalize($0.title) == text || $0.aliases.contains { normalize($0) == text } }
 }
 static func filtered(by query: String) -> [VocabularyEntry] {
  let query = normalize(query)
  guard !query.isEmpty else { return words }
  return words.filter { normalize($0.title).contains(query) || $0.aliases.contains { normalize($0).contains(query) } }
 }
 private static func normalize(_ value: String) -> String {
  value.lowercased().split { $0.isWhitespace || $0.isPunctuation }.joined(separator: " ")
 }
}
