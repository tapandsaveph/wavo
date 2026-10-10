import SwiftUI
import SafariServices

struct SigningReferenceView: UIViewControllerRepresentable {
 let entry: VocabularyEntry
 func makeUIViewController(context: Context) -> SFSafariViewController {
  let controller = SFSafariViewController(url: entry.referenceURL)
  controller.dismissButtonStyle = .done
  return controller
 }
 func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
struct LibraryView: View {
 let onUseWord: (String) -> Void
 @State private var query = ""
 @State private var reference: VocabularyEntry?
 var body: some View {
  NavigationStack {
   List {
    Section {
     Text("Look up a sign, then use a word in your message. These are learning references; word signs are not recognized by the camera yet.")
    }
    Section("Fingerspelling") {
     Button { reference = VocabularyCatalog.alphabet } label: {
      Label("View ASL alphabet", systemImage: "hand.raised.fingers.spread")
     }
     Text("J and Z involve movement and may need typing.").font(.caption).foregroundStyle(.secondary)
    }
    Section("Conversation signs") {
     if VocabularyCatalog.filtered(by: query).isEmpty {
      ContentUnavailableView.search(text: query)
     }
     ForEach(VocabularyCatalog.filtered(by: query)) { entry in
      NavigationLink {
       VStack(alignment: .leading, spacing: 20) {
        Text(entry.title).font(.largeTitle.bold())
        Label("Learning reference", systemImage: "book").foregroundStyle(.secondary)
        Text("View this sign on ASL University. The original reference opens inside the app and needs internet.")
        Button { reference = entry } label: {
         Label("View Signing Reference", systemImage: "play.rectangle").frame(maxWidth: .infinity)
        }.buttonStyle(.borderedProminent).controlSize(.large)
        Button("Add Word to Message") { onUseWord(entry.title) }
         .buttonStyle(.bordered).controlSize(.large)
        Text("This button adds a word you select manually. It does not recognize a sign through the camera.")
         .font(.caption).foregroundStyle(.secondary)
        Spacer()
        Text("Reference: ASL University · William G. Vicars / Lifeprint").font(.caption).foregroundStyle(.secondary)
       }.padding(24).navigationTitle(entry.title).navigationBarTitleDisplayMode(.inline)
      } label: {
       VStack(alignment: .leading, spacing: 5) {
        Text(entry.title).font(.headline)
        Text("View sign · manually add word").font(.caption).foregroundStyle(.secondary)
       }.padding(.vertical, 6)
      }
     }
    }
    Section("Availability") {
     Text("Reference pages may include signing videos or image sequences. They need internet and are not downloaded or saved by Wavo. If a reference cannot load, try again when connected.").font(.caption)
    }
   }.navigationTitle("ASL Library")
    .searchable(text: $query, prompt: "Find a sign")
    .sheet(item: $reference) { SigningReferenceView(entry: $0).ignoresSafeArea() }
  }
 }
}
