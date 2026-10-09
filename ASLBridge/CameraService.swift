import Foundation
import AVFoundation
import Vision
import CoreML
import Combine

// Capture/session/model state is confined to queue; published state is changed on main.
final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
 let session = AVCaptureSession()
 let capturedLetters = PassthroughSubject<LetterCandidate, Never>()
 @Published private(set) var candidate: LetterCandidate?
 @Published private(set) var status = "Tap Start Camera to spell a message."
 @Published private(set) var running = false
 private let queue = DispatchQueue(label: "asl.camera", qos: .userInitiated)
 private var configured = false
 private var desiredRunning = false
 private var model: ASLHandPoseClassifier17?
 private var lastFrame = Date.distantPast
 private var stability = LetterStabilityFilter()
 private let request: VNDetectHumanHandPoseRequest = {
  let request = VNDetectHumanHandPoseRequest(); request.maximumHandCount = 1; return request
 }()
 func start() {
  queue.async { self.desiredRunning = true }
  switch AVCaptureDevice.authorizationStatus(for: .video) {
  case .authorized: configureAndStart()
  case .notDetermined:
   AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted { self.configureAndStart() } else { self.publish(nil, "Camera access denied. You can still type.", running: false) }
   }
  default: publish(nil, "Enable Camera in Settings, or type your message.", running: false)
  }
 }
 func stop() {
  queue.async {
   self.desiredRunning = false
   self.stability.reset()
   if self.session.isRunning { self.session.stopRunning() }
   self.publish(nil, "Camera stopped. You can still type.", running: false)
  }
 }
 private func configureAndStart() {
  queue.async {
   guard self.desiredRunning else { return }
   do {
    if !self.configured {
     guard let url = Bundle.main.url(forResource: "ASLHandPoseClassifier17", withExtension: "mlmodelc") else { throw CameraFailure.model }
     self.model = try ASLHandPoseClassifier17(contentsOf: url)
     guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { throw CameraFailure.camera }
     let input = try AVCaptureDeviceInput(device: device)
     self.session.beginConfiguration(); defer { self.session.commitConfiguration() }
     self.session.sessionPreset = .medium
     let output = AVCaptureVideoDataOutput(); output.alwaysDiscardsLateVideoFrames = true
     output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
     output.setSampleBufferDelegate(self, queue: self.queue)
     guard self.session.canAddInput(input), self.session.canAddOutput(output) else { throw CameraFailure.camera }
     self.session.addInput(input)
     self.session.addOutput(output)
     self.configured = true
    }
    self.stability.reset()
    self.lastFrame = .distantPast
    self.session.startRunning()
    self.publish(nil, "Hold one hand clearly in view.", running: self.session.isRunning)
   } catch { self.publish(nil, "Camera or model unavailable. Try restarting the app, or type.", running: false) }
  }
 }
 func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
  let now = Date()
  guard desiredRunning, now.timeIntervalSince(lastFrame) >= 0.15 else { return }
  lastFrame = now
  do {
   try VNImageRequestHandler(cmSampleBuffer: buffer, orientation: .right, options: [:]).perform([request])
   guard let hand = request.results?.first, let model else {
    _ = stability.observe(nil, now: now)
    publish(nil, "No hand detected. Move your hand into view.", running: true); return
   }
   let result = try model.prediction(poses: hand.keypointsMultiArray())
   let label = result.label
   guard let probability = result.labelProbabilities[label] else {
    _ = stability.observe(LetterCandidate(letter: "", probability: 0, observedAt: now), now: now)
    publish(nil, "Prediction unavailable. You can type instead.", running: true); return
   }
   let letter = LetterCandidate(letter: label.uppercased(), probability: probability, observedAt: now)
   guard let stable = stability.observe(letter, now: now) else {
    let message = letter.isUsable(now: now) && probability >= 0.85
     ? (stability.alreadyCaptured(letter.letter) ? "Letter added. Change signs, or lower your hand to repeat it." : "Hold steady briefly to add this letter.")
     : "Uncertain — hold again. Keep your hand clearly lit."
    publish(nil, message, running: true); return
   }
   publish(stable, "Added \(stable.letter). Change signs, or lower your hand to repeat it.", running: true)
   DispatchQueue.main.async { self.capturedLetters.send(stable) }
  } catch { _ = stability.observe(LetterCandidate(letter: "", probability: 0, observedAt: now), now: now); publish(nil, "Could not read this hand pose. Try again.", running: true) }
 }
 private func publish(_ candidate: LetterCandidate?, _ status: String, running: Bool) {
  DispatchQueue.main.async { self.candidate = candidate; self.status = status; self.running = running }
 }
 private enum CameraFailure: Error { case camera, model }
}
