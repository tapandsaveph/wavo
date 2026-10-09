// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "BridgeCore", products: [.library(name: "BridgeCore", targets: ["BridgeCore"])], targets: [.target(name: "BridgeCore"), .testTarget(name: "BridgeCoreTests", dependencies: ["BridgeCore"])])
