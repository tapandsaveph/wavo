import Foundation
import AVFoundation
import Vision
import CoreML
import Combine

// Capture/session/model state is confined to queue; published state is changed on main.
final class CameraService: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
 let session = AVCaptureSession()
 let capturedWords = PassthroughSubject<String, Never>()
 let capturedLetters = PassthroughSubject<LetterCandidate, Never>()
 @Published private(set) var candidate: LetterCandidate?
 @Published private(set) var status = "Tap Start Camera to spell a message."
 @Published private(set) var running = false
 @Published private(set) var recording = false
 @Published private(set) var recordingStatus = "Record one natural sign per clip. No audio is recorded."
 @Published private(set) var latestRecording: URL?
 private let movieOutput = AVCaptureMovieFileOutput()
 private var recordingBusy = false
 private var discardRecording = false
 private var recordingWatchdog: DispatchWorkItem?
 private let queue = DispatchQueue(label: "asl.camera", qos: .userInitiated)
 private var configured = false
 private var desiredRunning = false
 private var model: ASLHandPoseClassifier17?
 private var helloModel: MLModel?
 private var thankYouModel: MLModel?
 private let faceRequest = VNDetectFaceLandmarksRequest()
 private var faceFrames: [[Double]] = []
 private var lastFaceCapture = Date.distantPast
 private var lastFaceAdded = Date.distantPast
 private var lastFacePrediction = Date.distantPast
 private var thankYouMode = false
 private var helloMode = false
 private var poses: [MLMultiArray] = []
 private var trackedFrames: [Bool] = []
 private var helloGate = HelloCaptureGate()
 private var missingSince: Date?
 private var lastPrediction = Date.distantPast
 private var lastFrame = Date.distantPast
 private var stability = LetterStabilityFilter()
 private let request: VNDetectHumanHandPoseRequest = {
  let request = VNDetectHumanHandPoseRequest(); request.maximumHandCount = 1; return request
 }()
 func start(recognizeHello: Bool = false, recognizeThankYou: Bool = false) {
  queue.async { self.desiredRunning = true; self.helloMode = recognizeHello || recognizeThankYou; self.thankYouMode = recognizeThankYou; self.poses.removeAll(); self.trackedFrames.removeAll(); self.helloGate.reset(); self.missingSince = nil; self.faceFrames.removeAll(); self.lastFaceCapture = .distantPast; self.lastFaceAdded = .distantPast }
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
   if self.recordingBusy { self.discardRecording = true; self.movieOutput.stopRecording() }
   self.stability.reset(); self.poses.removeAll(); self.trackedFrames.removeAll(); self.helloGate.reset()
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
    self.stability.reset(); self.poses.removeAll(); self.trackedFrames.removeAll(); self.helloGate.reset()
    self.lastFrame = .distantPast
    self.session.startRunning()
    self.publish(nil, "Hold one hand clearly in view.", running: self.session.isRunning)
   } catch { self.publish(nil, "Camera or model unavailable. Try restarting the app, or type.", running: false) }
  }
 }
 func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {
  let now = Date()
  guard !recordingBusy, desiredRunning, now.timeIntervalSince(lastFrame) >= (helloMode ? 1.0 / 15.0 : 0.07) else { return }
  if helloMode && now.timeIntervalSince(lastFrame) > 0.3 { poses.removeAll(); trackedFrames.removeAll() }
  lastFrame = now
  do {
   try VNImageRequestHandler(cmSampleBuffer: buffer, orientation: .right, options: [:]).perform([request])
   if thankYouMode {
    try VNImageRequestHandler(cmSampleBuffer: buffer, orientation: .right, options: [:]).perform([faceRequest])
    try processHello(hand: request.results?.first, now: now)
    try processFaceAware(hand: request.results?.first, face: faceRequest.results?.first, now: now)
    return
   }
   if helloMode {
    try processHello(hand: request.results?.first, now: now)
    return
   }
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
  } catch { poses.removeAll(); trackedFrames.removeAll(); _ = stability.observe(LetterCandidate(letter: "", probability: 0, observedAt: now), now: now); publish(nil, "Could not read this hand pose. Try again.", running: true) }
 }


 func recordExample(label: TrainingClipLabel, split: TrainingClipSplit) {
  queue.async {
   guard self.desiredRunning, self.session.isRunning, !self.recordingBusy else { return }
   do {
    if !self.session.outputs.contains(where: { $0 === self.movieOutput }) {
     self.session.beginConfiguration()
     guard self.session.canAddOutput(self.movieOutput) else {
      self.session.commitConfiguration(); throw CameraFailure.camera
     }
     self.session.addOutput(self.movieOutput)
     self.session.commitConfiguration()
    }
    guard let connection = self.movieOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) else { throw CameraFailure.camera }
    connection.videoRotationAngle = 90
    if connection.isVideoMirroringSupported { connection.automaticallyAdjustsVideoMirroring = false; connection.isVideoMirrored = false }
    let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let folder = documents.appendingPathComponent("TrainingClips").appendingPathComponent(split.folder).appendingPathComponent(label.folder)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let url = folder.appendingPathComponent("\(split.folder)-\(label.folder)-\(UUID().uuidString).mov")
    self.movieOutput.maxRecordedDuration = CMTime(seconds: 3, preferredTimescale: 600)
    self.recordingBusy = true; self.discardRecording = false
    self.stability.reset(); self.poses.removeAll(); self.trackedFrames.removeAll(); self.helloGate.reset()
    DispatchQueue.main.async { self.recording = true; self.latestRecording = nil; self.recordingStatus = "Recording \(label.rawValue) — sign now. Stops after 3 seconds." }
    self.movieOutput.startRecording(to: url, recordingDelegate: self)
    let watchdog = DispatchWorkItem { [weak self] in
     guard let self, self.recordingBusy else { return }
     self.discardRecording = true; self.movieOutput.stopRecording()
     DispatchQueue.main.async { self.recordingStatus = "Recording did not finish. Try again." }
    }
    self.recordingWatchdog = watchdog
    self.queue.asyncAfter(deadline: .now() + 8, execute: watchdog)
   } catch {
    DispatchQueue.main.async { self.recordingStatus = "Could not start recording. Stop and restart the camera, then try again." }
   }
  }
 }
 func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo url: URL, from connections: [AVCaptureConnection], error: Error?) {
  queue.async {
   self.recordingWatchdog?.cancel(); self.recordingWatchdog = nil
   let finished = error == nil || ((error as NSError?)?.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool == true)
   let keep = finished && !self.discardRecording
   self.recordingBusy = false
   self.poses.removeAll(); self.trackedFrames.removeAll(); self.stability.reset(); self.helloGate.reset(); self.lastFrame = .distantPast
   if !keep { try? FileManager.default.removeItem(at: url) }
   DispatchQueue.main.async {
    self.recording = false
    self.latestRecording = keep ? url : nil
    self.recordingStatus = keep ? "Clip saved on this iPhone. Record the next example, or share this clip." : "Clip was interrupted or could not be saved. Try again."
   }
  }
 }
 private func processFaceAware(hand: VNHumanHandPoseObservation?, face: VNFaceObservation?, now: Date) throws {
  if now.timeIntervalSince(lastFaceCapture) > 0.5 { faceFrames.removeAll() }
  guard now.timeIntervalSince(lastFaceCapture) >= 0.1 else { return }
  lastFaceCapture = now
  var values = Array(repeating: 0.0, count: 12)
  if let face, let hand {
   let points = try hand.recognizedPoints(.all)
   let box = face.boundingBox
   var mouth = CGPoint(x: box.midX, y: box.minY + box.height * 0.3)
   if let lips = face.landmarks?.outerLips, lips.pointCount > 0 {
    let points = lips.normalizedPoints
    mouth = CGPoint(x: box.minX + points.reduce(0.0) { $0 + Double($1.x) } / Double(points.count) * box.width,
                    y: box.minY + points.reduce(0.0) { $0 + Double($1.y) } / Double(points.count) * box.height)
   }
   values[0] = 1
   values[1] = Double(points.values.filter { $0.confidence >= 0.3 }.count) / 21
   let joints: [VNHumanHandPoseObservation.JointName] = [.wrist, .thumbTip, .indexTip, .middleTip, .ringTip]
   for (index, joint) in joints.enumerated() {
    if let point = points[joint], point.confidence >= 0.3 {
     values[2 + index * 2] = Double((point.location.x - mouth.x) / max(box.width, 0.01))
     values[3 + index * 2] = Double((point.location.y - mouth.y) / max(box.height, 0.01))
    }
   }
  }
  faceFrames.append(values)
  if faceFrames.count > 30 { faceFrames.removeFirst() }
  guard faceFrames.count == 30 else {
   publish(nil, "Watching for Hello or Thank you…", running: true); return
  }
  guard now.timeIntervalSince(lastFacePrediction) >= 0.3 else { return }
  lastFacePrediction = now
  guard faceFrames.suffix(10).contains(where: { $0[0] == 1 }), face != nil else {
   publish(nil, "Keep your face and hand visible.", running: true); return
  }
  if thankYouModel == nil {
   guard let url = Bundle.main.url(forResource: "WordGesturesExperimental", withExtension: "mlmodelc") else { throw CameraFailure.model }
   thankYouModel = try MLModel(contentsOf: url)
  }
  var features: [String: Any] = [:]
  for bin in 0..<8 {
   let start = bin * faceFrames.count / 8
   let end = max(start + 1, (bin + 1) * faceFrames.count / 8)
   for index in 0..<12 {
    features["b\(bin)f\(index)"] = faceFrames[start..<end].reduce(0.0) { $0 + $1[index] } / Double(end - start)
   }
  }
  let prediction = try thankYouModel!.prediction(from: MLDictionaryFeatureProvider(dictionary: features))
  let label = prediction.featureValue(for: "label")?.stringValue
  if label == "ThankYou", now.timeIntervalSince(lastFaceAdded) >= 4 {
   lastFaceAdded = now
   faceFrames.removeAll()
   publish(nil, "Experimental guess added. Check the draft before speaking.", running: true)

   DispatchQueue.main.async { self.capturedWords.send("Thank you") }
  } else {
   publish(nil, "Ready for Hello or Thank you. Review your draft before speaking.", running: true)
  }
 }
 private func processHello(hand: VNHumanHandPoseObservation?, now: Date) throws {
  func show(_ candidate: LetterCandidate?, _ message: String, running: Bool) {
   if !thankYouMode { self.publish(candidate, message, running: running) }
  }
  let points = try hand?.recognizedPoints(.all)
  let tracked = (points?[.wrist]?.confidence ?? 0) >= 0.3 && (points?.values.filter { $0.confidence >= 0.3 }.count ?? 0) >= 8
  if !tracked {
   if missingSince == nil { missingSince = now }
   if let missingSince, now.timeIntervalSince(missingSince) >= 0.3 {
    helloGate.reset(); poses.removeAll(); trackedFrames.removeAll()
   }
  } else { missingSince = nil }
  let pose: MLMultiArray
  if tracked, let hand { pose = try hand.keypointsMultiArray() }
  else {
   pose = try MLMultiArray(shape: [1, 3, 21], dataType: .float32)
   for index in 0..<pose.count { pose[index] = 0 }
  }
  poses.append(pose); trackedFrames.append(tracked)
  if poses.count > 15 { poses.removeFirst(); trackedFrames.removeFirst() }
  guard HelloWindowCheck.canPredict(trackedFrames) else {
   show(nil, tracked ? "Watching your sign…" : "Move your hand clearly into view.", running: true)
   return
  }
  if helloModel == nil {
   guard let url = Bundle.main.url(forResource: "HelloExperimental", withExtension: "mlmodelc") else { throw CameraFailure.model }
   helloModel = try MLModel(contentsOf: url)
  }
  guard now.timeIntervalSince(lastPrediction) >= 0.2 else { return }
  lastPrediction = now
  let sequence = try MLMultiArray(shape: [15, 3, 21], dataType: .float32)
  for frame in 0..<15 {
   for channel in 0..<3 {
    for joint in 0..<21 {
     sequence[[NSNumber(value: frame), NSNumber(value: channel), NSNumber(value: joint)]] = poses[frame][[0, NSNumber(value: channel), NSNumber(value: joint)]]
    }
   }
  }
  let input = try MLDictionaryFeatureProvider(dictionary: ["poses": sequence])
  guard let output = try helloModel?.prediction(from: input),
        let label = output.featureValue(for: "label")?.stringValue,
        let probability = output.featureValue(for: "labelProbabilities")?.dictionaryValue[label]?.doubleValue else { throw CameraFailure.model }
  let target = "Hello"
  let gateLabel = label == target ? label : "Other"
  if helloGate.observe(label: gateLabel, confidence: probability) {
   let word = label == "ThankYou" ? "Thank you" : "Hello"
   show(nil, "Added \(word). Review your message before speaking.", running: true)

   DispatchQueue.main.async { self.capturedWords.send(word) }
  } else {
   let word = thankYouMode ? "Thank you" : "Hello"
   let score = Int((probability * 100).rounded())
   let message: String
   if label != target { message = "Ready for \(word)." }
   else if probability < 0.9 { message = "Possible \(word): \(score)%. Needs 90% to add." }
   else { message = "Sign already added. Lower your hand before repeating." }
   show(nil, message, running: true)
  }
 }
 private func publish(_ candidate: LetterCandidate?, _ status: String, running: Bool) {
  DispatchQueue.main.async {
   if candidate != nil || self.candidate != nil { self.candidate = candidate }
   if self.status != status { self.status = status }
   if self.running != running { self.running = running }
  }
 }
 private enum CameraFailure: Error { case camera, model }
}
