import SwiftUI
import OSLog
@main
struct ASLBridgeApp: App {
 var body: some Scene { WindowGroup {
  ConversationView()
   .task {
    #if DEBUG
    if ProcessInfo.processInfo.arguments.contains("--offline-voice-self-test") {
     let logger = Logger(subsystem: "com.nehroranay.aslbridge", category: "voice-test")
     do {
      let start = Date()
      let url = try await OfflineVoice().generate("Hello everyone. My name is Sophia. Thank you for listening.")
      let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let output = documents.appendingPathComponent("offline-voice-test.wav")
      try? FileManager.default.removeItem(at: output)
      try FileManager.default.moveItem(at: url, to: output)
      let report = "Generated locally in \(Date().timeIntervalSince(start)) seconds."
      try report.write(to: documents.appendingPathComponent("offline-voice-test.txt"), atomically: true, encoding: .utf8)
      logger.info("\(report, privacy: .public)")
     } catch { logger.error("Voice test failed: \(String(describing: error), privacy: .public)") }
    }
    #endif
   }
 } }
}
