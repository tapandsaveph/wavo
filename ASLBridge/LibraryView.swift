import SwiftUI
struct LibraryView: View {
 var body: some View {
  NavigationStack {
   List {
    Section {
     Text("Camera recognition currently supports alphabet poses. Whole-word signing and sentences are not automatically translated.")
      .font(.body)
    }
    Section("Fingerspelling") {
     Link(destination: URL(string: "https://www.lifeprint.com/asl101/fingerspelling/fingerspelling.htm")!) {
      Label("Open ASL alphabet reference", systemImage: "hand.raised.fingers.spread")
     }
     Text("J and Z involve movement. The current model classifies individual hand poses; these letters may need typing.")
      .foregroundStyle(.secondary)
    }
    Section("Conversation signs") {
     ForEach(VocabularyCatalog.words) { entry in
      Link(destination: entry.referenceURL) {
       VStack(alignment: .leading, spacing: 5) {
        Text(entry.title).font(.headline)
        Text(entry.detail).font(.caption).foregroundStyle(.secondary)
        Text("Open signing reference ↗").font(.caption)
       }.padding(.vertical, 4)
      }
     }
    }
    Section("About the references") {
     Text("References open ASL University (Lifeprint) in your browser and need internet. Review signs with an ASL signer. No signing videos are bundled yet.")
    }
   }.navigationTitle("ASL Library")
  }
 }
}
