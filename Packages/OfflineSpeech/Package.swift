// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "OfflineSpeech", platforms: [.iOS("18.0")],
 products: [.library(name: "sherpa-onnx", targets: ["SherpaOnnx"])],
 targets: [
  .binaryTarget(name: "SherpaOnnxIOS", path: "sherpa-onnx.xcframework"),
  .binaryTarget(name: "OnnxruntimeIOS", path: "onnxruntime.xcframework"),
  .target(name: "SherpaOnnx", dependencies: ["SherpaOnnxIOS", "OnnxruntimeIOS"], linkerSettings: [.linkedLibrary("c++")])
 ])
