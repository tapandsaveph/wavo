import SwiftUI
import AVFoundation
import UIKit

struct ConversationView: View {
 @StateObject private var camera = CameraService()
 @StateObject private var speech = SpeechService()
 @State private var draft = MessageDraft()
 @State private var mode = InputMode.spell
 @State private var tab = 0
 @State private var showTraining = false
 @State private var showEditor = false
 @State private var trainingLabel = TrainingClipLabel.thankYou
 @State private var trainingSplit = TrainingClipSplit.training
 @State private var reference: VocabularyEntry?
 @Environment(\.accessibilityReduceMotion) private var reduceMotion
 @Environment(\.scenePhase) private var scenePhase
 private enum InputMode: String, CaseIterable { case spell = "Spell", signs = "Signs (Test)", listen = "Listen" }
 private let teal = Color.yellow
 var body: some View {
  cameraScreen
   .sheet(isPresented: Binding(get: { tab == 1 }, set: { if !$0 { tab = 0 } })) {
    NavigationStack {
     LibraryView { word in
      camera.stop(); speech.stopAll(); draft.addSpace(); draft.text += word; mode = .spell; tab = 0
     }
     .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { tab = 0 } } }
    }
   }
   .sheet(isPresented: $showTraining) {
    NavigationStack {
     ScrollView { trainingControls.padding(20) }
      .navigationTitle("Record examples")
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showTraining = false } } }
    }
   }
   .sheet(item: $reference) { SigningReferenceView(entry: $0).ignoresSafeArea() }
   .onReceive(camera.capturedLetters) { letter in
    if !camera.recording && tab == 0 && mode == .spell && scenePhase == .active && camera.running && !speech.activity.isSpeaking { draft.add(letter, now: Date()) }
   }
   .onReceive(camera.capturedWords) { word in
    if !camera.recording && tab == 0 && mode == .signs && scenePhase == .active && camera.running && !speech.activity.isSpeaking {
     draft.addSpace(); draft.text += word; draft.addSpace()
    }
   }
   .onChange(of: mode) { _, _ in camera.stop() }
   .onChange(of: tab) { _, _ in camera.stop(); speech.stopAll() }
   .onChange(of: scenePhase) { _, phase in if phase != .active { camera.stop(); speech.stopAll() } }
   .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in speech.stopAll() }
 }

 private var cameraScreen: some View {
  ZStack {
   Color.black.ignoresSafeArea()
   CameraPreview(session: camera.session).ignoresSafeArea()
    .opacity(camera.running ? 1 : 0).accessibilityHidden(true)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: camera.running)
   LinearGradient(colors: [.black.opacity(0.12), .clear, .black.opacity(0.12)], startPoint: .top, endPoint: .bottom)
    .ignoresSafeArea().allowsHitTesting(false)
   VStack(spacing: 8) {
    HStack {
     Menu {
      Picker("Input", selection: $mode) {
       ForEach(InputMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
      }
     } label: { Label(mode.rawValue, systemImage: "chevron.down").padding(.horizontal, 12).frame(minHeight: 44) }
      .disabled(camera.recording).background(.regularMaterial, in: Capsule())
     Spacer()
     Button {
      if speech.continuousListening { speech.stopAll() } else { speech.startContinuousListening() }
     } label: {
      Image(systemName: speech.continuousListening ? "mic.fill" : "mic.slash")
       .frame(width: 44, height: 44)
     }.accessibilityLabel(speech.continuousListening ? "Pause live captions" : "Start live captions")
      .background(.regularMaterial, in: Circle())
     Menu {
      Button("Library", systemImage: "book") { tab = 1 }
      Button("Record examples", systemImage: "record.circle") { showTraining = true }
     } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
      .accessibilityLabel("Library and recording options")
      .background(.regularMaterial, in: Circle())
    }
    if mode != .listen && (speech.continuousListening || !speech.transcript.isEmpty) {
     VStack(alignment: .leading, spacing: 4) {
      Text(speech.status).font(.caption).foregroundStyle(.yellow)
      if !speech.transcript.isEmpty { Text(String(speech.transcript.suffix(220))).font(.title2).lineLimit(4) }
     }
      .frame(maxWidth: .infinity, alignment: .leading).padding(12)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
      .accessibilityLabel("Their reply: \(speech.transcript)")
    }
    VStack(spacing: 12) {
     if mode != .listen {
      VStack(spacing: 16) {
      Image("WavoLogo")
       .resizable().scaledToFit().frame(width: 88, height: 88)
       .clipShape(RoundedRectangle(cornerRadius: 22))
       .accessibilityHidden(true)
      Text("Wavo").font(.largeTitle.weight(.bold)).foregroundStyle(.yellow)
      Text("Make yourself heard.")
       .font(.title2.weight(.semibold)).multilineTextAlignment(.center)
      Button {
       if !speech.continuousListening { speech.startContinuousListening() }
       camera.start(recognizeHello: mode == .signs, recognizeThankYou: mode == .signs)
      } label: {
       Label("Start camera", systemImage: "camera.fill")
        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
        .foregroundStyle(.black)
        .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
      }.buttonStyle(.plain)
       .disabled(camera.recording)
      Text("Keep your hand in view to sign, or tap the message box to type.")
       .font(.body).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
       .fixedSize(horizontal: false, vertical: true)
      }.fixedSize(horizontal: false, vertical: true)
     }
    }.padding(.horizontal, 24).frame(maxWidth: .infinity, maxHeight: .infinity)
     .opacity(camera.running ? 0 : 1)
     .allowsHitTesting(!camera.running)
     .accessibilityHidden(camera.running)
     .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: camera.running)
    if mode != .listen {
     HStack(spacing: 8) {
      Text(camera.status).font(.caption).lineLimit(2)
       .accessibilityLabel("Camera status: \(camera.status)")
      Spacer(minLength: 0)
      if camera.running {
       Button { camera.stop() } label: {
        Label("Stop camera", systemImage: "stop.circle").frame(minHeight: 44)
       }.disabled(camera.recording)
      }
     }.padding(.horizontal, 12).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
     compactMessage
    } else {
     ScrollView { listenView }.frame(maxHeight: 360).padding(12)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
   }.padding(.horizontal, 16).padding(.vertical, 8)
  }.preferredColorScheme(.dark).tint(teal)
 }
 private var compactMessage: some View {
  VStack(spacing: 4) {
   Button { showEditor = true } label: {
    HStack {
     Text(draft.text.isEmpty ? "Type or sign…" : draft.text)
      .font(.title3).foregroundStyle(.white).lineLimit(2)
      .frame(maxWidth: .infinity, alignment: .leading)
     Image(systemName: "pencil").foregroundStyle(.yellow)
    }.frame(minHeight: 44)
   }.accessibilityLabel("Edit your message: \(draft.text)")
   HStack(spacing: 8) {
    Button("Space") { draft.addSpace() }.frame(minHeight: 44)
    Button { draft.deleteLast() } label: { Image(systemName: "delete.left").frame(width: 44, height: 44) }
     .accessibilityLabel("Delete last character").disabled(draft.text.isEmpty)
    Menu {
     Button("Clear message", role: .destructive) { draft.clear() }
    } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
     .accessibilityLabel("Message options").disabled(draft.text.isEmpty)
    Spacer(minLength: 0)
    Button {
     if speech.activity.isSpeaking { speech.stopSpeakingAndResume() } else { speech.speak(draft.text) }
    } label: {
     Label(speech.activity.isSpeaking ? "Stop" : "Speak", systemImage: speech.activity.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
      .fixedSize(horizontal: true, vertical: false).frame(minHeight: 44).padding(.horizontal, 8)
    }.buttonStyle(.borderedProminent)
     .foregroundStyle(draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white : Color.black)
     .disabled(camera.recording || draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
   }
   if mode == .signs { Text("Experimental signs · Review before speaking").font(.caption).foregroundStyle(.secondary) }
  }.padding(.horizontal, 12).padding(.vertical, 8)
   .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
   .sheet(isPresented: $showEditor) {
    NavigationStack {
     ScrollView {
      VStack(alignment: .leading, spacing: 12) {
       if speech.continuousListening || !speech.transcript.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
         Text(speech.status).font(.caption).foregroundStyle(.yellow)
         Text(speech.transcript.isEmpty ? "Listening…" : String(speech.transcript.suffix(220)))
          .font(.title3).lineLimit(4)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
         .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
         .accessibilityLabel("Their reply: \(speech.transcript)")
       }
       spellView
      }.padding(16)
     }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showEditor = false } } }
    }.presentationDetents([.large])

   }
 }
 private var trainingControls: some View {
   DisclosureGroup("Record examples for the model") {
    VStack(alignment: .leading, spacing: 12) {
     Picker("What will you record?", selection: $trainingLabel) {
      ForEach(TrainingClipLabel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }.disabled(camera.recording)
     Picker("Use clip for", selection: $trainingSplit) {
      ForEach(TrainingClipSplit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
     }.pickerStyle(.segmented).disabled(camera.recording)
     Text("Keep your face, whole hand and wrist visible. Make one natural sign during the three-second recording. For ordinary movement, adjust glasses or touch your face without signing.").font(.caption).foregroundStyle(.secondary)
     Button(camera.recording ? "Recording…" : "Record 3-second clip", systemImage: "record.circle") {
      speech.stopAll(); camera.recordExample(label: trainingLabel, split: trainingSplit)
     }.buttonStyle(.borderedProminent).disabled(!camera.running || camera.recording)
     if !camera.running { Text("Start Camera above to record.").font(.caption) }
     Text(camera.recordingStatus).font(.subheadline).accessibilityAddTraits(.updatesFrequently)
     if let url = camera.latestRecording {
      ShareLink(item: url) { Label("Share saved clip", systemImage: "square.and.arrow.up") }
     }
     Text("Clips stay on your iPhone until you share them. Training and testing recordings are saved separately. Recording does not retrain the model automatically.").font(.caption).foregroundStyle(.secondary)
    }.padding(.top, 8)
   }
 }
 private var spellView: some View {
  VStack(alignment: .leading, spacing: 12) {
   ZStack(alignment: .topLeading) {
    if draft.text.isEmpty {
     Text("Type here…").font(.title2).foregroundStyle(.secondary)
      .padding(.horizontal, 16).padding(.vertical, 18).allowsHitTesting(false)
    }
    FocusedMessageInput(text: $draft.text).frame(height: 110).padding(8)
   }.background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.yellow, lineWidth: 1.5))
   HStack {
    Button("Space") { draft.addSpace() }
    Button("Delete", systemImage: "delete.left") { draft.deleteLast() }.disabled(draft.text.isEmpty)
    Spacer()
    Button("Clear") { draft.clear() }.disabled(draft.text.isEmpty)
   }.buttonStyle(.bordered)
   Button {
    if speech.activity.isSpeaking { speech.stopSpeakingAndResume() } else { speech.speak(draft.text) }
   } label: {
    Label(speech.activity.isSpeaking ? "Stop Speaking" : "Speak", systemImage: speech.activity.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
     .frame(maxWidth: .infinity).padding(.vertical, 8)
   }.buttonStyle(.borderedProminent).controlSize(.large)
    .foregroundStyle(draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white : Color.black)
    .disabled(camera.recording || draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
   Text(speech.status).font(.caption).foregroundStyle(.secondary)
   Text("Review your message, then tap Speak.").font(.caption).foregroundStyle(.secondary)
  }
 }
 private var listenView: some View {
  VStack(alignment: .leading, spacing: 16) {
   Text("Read a spoken reply").font(.title2.bold())
   Text("The other person speaks. Their words appear here.").foregroundStyle(.secondary)
   if speech.transcript.isEmpty {
    Text("Captions will appear here. You can also tap below and type a reply.").foregroundStyle(.secondary)
   }
   TextEditor(text: $speech.transcript).font(.title).frame(height: 160).padding(12)
    .scrollContentBackground(.hidden).accessibilityLabel("Editable reply captions")
   if let entry = VocabularyCatalog.matching(speech.transcript) {
    Button {
     speech.stopAll(); reference = entry
    } label: {
     Label("View sign: \(entry.title)", systemImage: "play.rectangle")
    }.buttonStyle(.bordered)
    Text("Reference for this word only; captions are not translated into full ASL sentences.")
     .font(.caption).foregroundStyle(.secondary)
   }
   Text(speech.status).foregroundStyle(.secondary)
   Button {
    camera.stop()
    if speech.continuousListening { speech.stopAll() } else { speech.startContinuousListening() }
   } label: {
    Label(speech.activity.isListening ? "Stop Listening" : "Start Listening", systemImage: speech.activity.isListening ? "stop.fill" : "mic.fill")
     .frame(maxWidth: .infinity).padding(.vertical, 8)
   }.buttonStyle(.borderedProminent).controlSize(.large).foregroundStyle(.black)
   Button("Clear Captions") { speech.stopAll(); speech.transcript = "" }.buttonStyle(.bordered)
   Text("English captions run on this device when supported. Audio and conversations are not saved.").font(.caption).foregroundStyle(.secondary)
  }
 }
}

// Focus belongs to the presented input; request it only after UIKit attaches its window.
private struct FocusedMessageInput: UIViewRepresentable {
 @Binding var text: String
 func makeCoordinator() -> Coordinator { Coordinator(self) }
 func makeUIView(context: Context) -> AutoFocusTextView {
  let view = AutoFocusTextView()
  view.delegate = context.coordinator
  view.backgroundColor = .clear
  view.textColor = .label
  view.tintColor = .systemYellow
  view.font = .preferredFont(forTextStyle: .title2)
  view.adjustsFontForContentSizeCategory = true
  view.autocorrectionType = .no
  view.accessibilityLabel = "Message to speak"
  view.text = text
  return view
 }
 func updateUIView(_ view: AutoFocusTextView, context: Context) {
  context.coordinator.parent = self
  if view.text != text { view.text = text }
 }
 final class Coordinator: NSObject, UITextViewDelegate {
  var parent: FocusedMessageInput
  init(_ parent: FocusedMessageInput) { self.parent = parent }
  func textViewDidChange(_ textView: UITextView) { parent.text = textView.text }
 }
}
private final class AutoFocusTextView: UITextView {
 private var requestedFocus = false
 override func didMoveToWindow() {
  super.didMoveToWindow()
  guard window != nil, !requestedFocus else { return }
  requestedFocus = true
  DispatchQueue.main.async { [weak self] in
   guard let self, self.window != nil else { return }
   self.becomeFirstResponder()
  }
 }
}
