#!/bin/bash
# Downloads build dependencies directly from upstream; runtime inference stays offline.
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
task_tmp="$(mktemp -d "${TMPDIR:-/tmp}/aslbridge-voice.XXXXXX")"
trap 'rm -rf "$task_tmp"' EXIT

fetch() {
  curl --fail --location --retry 3 "$1" --output "$task_tmp/$2"
  printf '%s  %s\n' "$3" "$task_tmp/$2" | shasum -a 256 --check
}

fetch 'https://github.com/k2-fsa/sherpa-onnx/releases/download/xcframework/sherpa-onnx-v1.13.8-ios-static.xcframework.zip' sherpa.zip 6b8e769cb153343270fdccbe92e3b3db0d1c421d67fa0989ab01fdf5b2fcf2de
fetch 'https://github.com/csukuangfj/onnxruntime-libs/releases/download/v1.28.2/onnxruntime-ios-static-xcframework-1.28.2.xcframework.zip' onnx.zip 2c2299acbb461d26d4bac4bc85985d40e7c7177ed6072703ae0846d88b0b4599
fetch 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-ljspeech-medium-int8.tar.bz2' voice.tar.bz2 24dc3bd77dd48c291e52c297878d3437c9492f245d823d7f6a06c4bbb67f4b6b

unzip -q "$task_tmp/sherpa.zip" -d "$task_tmp/sherpa"
unzip -q "$task_tmp/onnx.zip" -d "$task_tmp/onnx"
tar -xjf "$task_tmp/voice.tar.bz2" -C "$task_tmp"
mkdir -p "$repo_root/Packages/OfflineSpeech" "$repo_root/ASLBridge/Resources/OfflineVoice"
cp -R "$task_tmp/sherpa/sherpa-onnx.xcframework" "$repo_root/Packages/OfflineSpeech/"
cp -R "$task_tmp/onnx/onnxruntime.xcframework" "$repo_root/Packages/OfflineSpeech/"
cp -R "$task_tmp/vits-piper-en_US-ljspeech-medium-int8/." "$repo_root/ASLBridge/Resources/OfflineVoice/"
test -s "$repo_root/ASLBridge/Resources/OfflineVoice/en_US-ljspeech-medium.onnx"
test -s "$repo_root/Packages/OfflineSpeech/sherpa-onnx.xcframework/Info.plist"
test -s "$repo_root/Packages/OfflineSpeech/onnxruntime.xcframework/Info.plist"
echo 'Offline voice dependencies ready. Open ASLBridge.xcodeproj in Xcode.'
