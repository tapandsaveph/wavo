import Foundation
import SherpaOnnx

// The actor owns the native model and serializes inference away from the UI.
actor OfflineVoice {
 private var synthesizer: SherpaOnnxOfflineTtsWrapper?
 func generate(_ text: String) throws -> URL {
  if synthesizer == nil {
   guard let folder = Bundle.main.url(forResource: "OfflineVoice", withExtension: nil) else { throw Failure.missingFiles }
   let vits = sherpaOnnxOfflineTtsVitsModelConfig(
    model: folder.appendingPathComponent("en_US-ljspeech-medium.onnx").path,
    tokens: folder.appendingPathComponent("tokens.txt").path,
    dataDir: folder.appendingPathComponent("espeak-ng-data").path
   )
   let model = sherpaOnnxOfflineTtsModelConfig(vits: vits, numThreads: 2)
   var config = sherpaOnnxOfflineTtsConfig(model: model)
   let instance = SherpaOnnxOfflineTtsWrapper(config: &config)
   guard instance.tts != nil else { throw Failure.initialization }
   synthesizer = instance
  }
  guard let synthesizer else { throw Failure.initialization }
  let audio = synthesizer.generate(text: text, sid: 0, speed: 1)
  guard audio.audio != nil, audio.n > 0 else { throw Failure.generation }
  let url = FileManager.default.temporaryDirectory.appendingPathComponent("speech-\(UUID().uuidString).wav")
  guard audio.save(filename: url.path) == 1 else { throw Failure.generation }
  return url
 }
 private enum Failure: Error { case missingFiles, initialization, generation }
}
