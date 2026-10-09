# Bundled offline voice

Speak generates arbitrary message text locally with sherpa-onnx 1.13.8 and the int8 Piper en_US-ljspeech-medium voice, then plays the resulting WAV. No API key, server, or runtime download is required. The original Apple voice remains a failure fallback.

The actor owns and serializes native inference. SpeechService cancels stale playback requests, cleans temporary audio, pauses captions during generation/playback, and resumes continuous captions afterward. Cancellation discards an in-flight result; it does not immediately interrupt native inference.

## Verification

- Debug iOS and arm64 iOS Simulator builds pass.
- A simulator test generated “Hello everyone. My name is Sophia. Thank you for listening.” locally in 1.33 seconds, producing 3.81 seconds of 22,050 Hz audio. This is a simulator measurement, not iPhone latency.
- The update was installed and launched on the iPhone. Physical playback and airplane-mode success have not yet been reported.
- Debug-only launch argument `--offline-voice-self-test` generates Documents/offline-voice-test.wav and a timing report. No test runs during normal launches or in Release builds.

## Dependencies and reproducibility

Run `bash scripts/setup-offline-voice.sh` before opening the project on a fresh checkout. It downloads pinned frameworks and voice files directly from upstream and verifies SHA-256 checksums. They remain git-ignored locally and are included in the built app; runtime synthesis needs no download. The voice folder is about 37 MiB. Frameworks include device and simulator slices.

Verified archive SHA-256 against upstream package manifests:

- sherpa-onnx iOS static: 6b8e769cb153343270fdccbe92e3b3db0d1c421d67fa0989ab01fdf5b2fcf2de
- ONNX Runtime iOS static: 2c2299acbb461d26d4bac4bc85985d40e7c7177ed6072703ae0846d88b0b4599

See THIRD_PARTY_NOTICES.md. eSpeak NG is GPL-3.0-or-later; redistribution requires compliance beyond retaining notices. No App Store licensing clearance is claimed.
