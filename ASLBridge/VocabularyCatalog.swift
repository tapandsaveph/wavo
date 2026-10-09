import Foundation
struct VocabularyEntry: Identifiable {
 let id: String
 let title: String
 let detail: String
 let referenceURL: URL
}
enum VocabularyCatalog {
 // Links open the original author's reference; no downloaded signing media is redistributed.
 static let words: [VocabularyEntry] = [
  .init(id: "hello", title: "Hello", detail: "Reference only · camera recognition not available", referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/h/hello.htm")!),
  .init(id: "name", title: "Name", detail: "Reference only · camera recognition not available", referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/n/name.htm")!),
  .init(id: "thank-you", title: "Thank you", detail: "Reference only · camera recognition not available", referenceURL: URL(string: "https://www.lifeprint.com/asl101/pages-signs/t/thankyou.htm")!)
 ]
}
