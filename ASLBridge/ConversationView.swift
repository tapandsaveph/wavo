import SwiftUI
import AVFoundation

struct ConversationView: View {
 @StateObject private var camera = CameraService()
 @StateObject private var speech = SpeechService()
 @State private var draft = MessageDraft()
 @State private var mode = InputMode.spell
 @State private var tab = 0
 @Environment(\.scenePhase) private var scenePhase
 private enum InputMode: String, CaseIterable { case spell = "Spell", listen = "Listen" }
 private let teal = Color(red: 0.05, green: 0.38, blue: 0.39)
 var body: some View {
  TabView(selection: $tab) {
   NavigationStack {
    ScrollView {
     VStack(alignment: .leading, spacing: 20) {
      Text("Your words. A shared conversation.").font(.subheadline).foregroundStyle(.secondary)
      Picker("Input", selection: $mode) {
       ForEach(InputMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }.pickerStyle(.segmented)
      if mode == .spell { spellView } else { listenView }
     }.padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("ASL Bridge")
    .navigationBarTitleDisplayMode(.inline)
    .scrollDismissesKeyboard(.interactively)
   }.tabItem { Label("Conversation", systemImage: "bubble.left.and.bubble.right") }.tag(0)
   LibraryView().tabItem { Label("Library", systemImage: "book") }.tag(1)
  }.tint(teal)
   .onChange(of: mode) { _, _ in camera.stop(); speech.stopAll() }
   .onChange(of: tab) { _, _ in camera.stop(); speech.stopAll() }
   .onChange(of: scenePhase) { _, phase in if phase != .active { camera.stop(); speech.stopAll() } }
   .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in speech.stopAll() }
 }
 private var spellView: some View {
  VStack(alignment: .leading, spacing: 16) {
   Text("Spell your message").font(.title2.bold())
   ZStack(alignment: .bottomLeading) {
    CameraPreview(session: camera.session)
    if !camera.running {
     Color(.secondarySystemGroupedBackground)
     VStack(spacing: 12) {
      Image(systemName: "hand.raised").font(.system(size: 36))
      Text("Use the camera, or type below.").font(.subheadline)
     }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    TimelineView(.periodic(from: .now, by: 0.2)) { context in
     if let candidate = camera.candidate, candidate.isUsable(now: context.date) {
      Text(candidate.letter).font(.system(size: 48, weight: .bold, design: .rounded))
       .foregroundStyle(.white).padding(12).background(teal, in: RoundedRectangle(cornerRadius: 14)).padding(12)
     }
    }
   }.frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 22))
   Text(camera.status).font(.subheadline).foregroundStyle(.secondary).accessibilityLabel("Camera status: \(camera.status)")
   HStack {
    Button(camera.running ? "Stop Camera" : "Start Camera", systemImage: camera.running ? "camera.fill" : "camera") {
     if camera.running { camera.stop() } else { speech.stopAll(); camera.start() }
    }.buttonStyle(.bordered).controlSize(.large)
    TimelineView(.periodic(from: .now, by: 0.2)) { context in
     Button("Add Letter", systemImage: "plus") { draft.add(camera.candidate, now: Date()) }
      .buttonStyle(.borderedProminent).controlSize(.large)
      .disabled(!(camera.candidate?.isUsable(now: context.date) ?? false))
    }
   }
   Text("Your message").font(.headline)
   TextEditor(text: $draft.text).frame(minHeight: 110).padding(8)
    .background(.background, in: RoundedRectangle(cornerRadius: 16))
    .font(.title2).accessibilityLabel("Your editable message")
   HStack {
    Button("Space") { draft.addSpace() }
    Button("Delete", systemImage: "delete.left") { draft.deleteLast() }.disabled(draft.text.isEmpty)
    Spacer()
    Button("Clear") { draft.clear() }.disabled(draft.text.isEmpty)
   }.buttonStyle(.bordered)
   Button {
    if speech.activity.isSpeaking { speech.stopAll() } else { camera.stop(); speech.speak(draft.text) }
   } label: {
    Label(speech.activity.isSpeaking ? "Stop Speaking" : "Speak Message", systemImage: speech.activity.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
     .frame(maxWidth: .infinity).padding(.vertical, 8)
   }.buttonStyle(.borderedProminent).controlSize(.large)
    .disabled(draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
   Text(speech.status).font(.caption).foregroundStyle(.secondary)
   Text("Review your message before speaking. This prototype recognizes alphabet poses, not full ASL sentences.").font(.caption).foregroundStyle(.secondary)
  }
 }
 private var listenView: some View {
  VStack(alignment: .leading, spacing: 16) {
   Text("Read a spoken reply").font(.title2.bold())
   Text("The other person speaks. Their words appear here.").foregroundStyle(.secondary)
   if speech.transcript.isEmpty {
    Text("Captions will appear here. You can also tap below and type a reply.").foregroundStyle(.secondary)
   }
   TextEditor(text: $speech.transcript).font(.title).frame(minHeight: 240).padding(12)
    .background(.background, in: RoundedRectangle(cornerRadius: 18)).accessibilityLabel("Editable reply captions")
   Text(speech.status).foregroundStyle(.secondary)
   Button {
    camera.stop()
    if speech.activity.isListening { speech.stopListening() } else { speech.startListening() }
   } label: {
    Label(speech.activity.isListening ? "Stop Listening" : "Start Listening", systemImage: speech.activity.isListening ? "stop.fill" : "mic.fill")
     .frame(maxWidth: .infinity).padding(.vertical, 8)
   }.buttonStyle(.borderedProminent).controlSize(.large)
   Button("Clear Captions") { speech.stopAll(); speech.transcript = "" }.buttonStyle(.bordered)
   Text("English captions run on this device when supported. Audio and conversations are not saved.").font(.caption).foregroundStyle(.secondary)
  }
 }
}
