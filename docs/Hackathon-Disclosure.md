# Hackathon disclosure — Wavo

Native iPhone prototype helping a Deaf signer compose a reviewed spoken message and read a hearing person's replies as captions. Supports fingerspelled alphabet poses and experimental Hello / Thank you recognition, not unrestricted conversational ASL.

## Technology inventory

| Technology | Purpose and provenance |
| --- | --- |
| Swift, SwiftUI, Xcode, iOS 18+ | Native application and build tooling |
| Apple AVFoundation / AVFAudio | Camera, microphone, training clip recording, audio playback and system speech fallback |
| Apple Vision | Local hand joints and face landmarks |
| Apple Core ML | Local bundled recognition model inference |
| Apple Create ML | Local training of Hello hand-action classifier and Thank you face-relative random forest |
| ASLHandPoseClassifier17.mlmodel | Pretrained alphabet model reused from https://github.com/liudasbar/ASL-Recognizer; MIT notice preserved |
| HelloExperimental.mlmodel | Hackathon model trained on user-provided sign and ordinary-movement recordings |
| WordGesturesExperimental.mlmodel | Hackathon experimental Thank you model using temporal face-relative hand features |
| Apple Speech / SFSpeechRecognizer | On-device English captions; supported device and installed recognition assets required |
| Piper en_US-ljspeech-medium int8 | Bundled pretrained offline neural voice; not trained by this team |
| sherpa-onnx 1.13.8, ONNX Runtime 1.28.2, eSpeak NG | Local speech inference and phonemization |
| Foundation, Combine, OSLog | Files, state updates and diagnostic logging |
| SafariServices, Lifeprint / ASL University | External reference pages; media is not redistributed |
| Swift Package Manager, Swift Testing | Dependency packaging and core tests |
| OpenAI Codex | AI-assisted implementation, debugging and verification |
| Google Gemini | Development advice supplied by the user; not an application dependency |
| ui-ux-pro-max, web-design-guidelines skills | Design guidance adapted to SwiftUI |

## Reused work and hackathon contributions

We consulted and cloned liudasbar/ASL-Recognizer, reused its alphabet model, and used its camera-first layout as a visual reference. The submitted SwiftUI interface and camera/speech services were developed for this project. We do not claim authorship of the upstream pretrained model or its training dataset. Its original training-data provenance has not been independently audited.

Hackathon work includes automatic stable letter capture, repeat controls, editable reviewed messages, continuous captions and restart handling, caption pause/resume during speech, camera lifecycle and empty state, sign training experiments, local clip recording, and bundled neural voice integration. Existing voice models, runtimes and Apple frameworks are disclosed above.

Roboflow and SignAlphaSet were explored experimentally; Google / WLASL alternatives were discussed. These datasets are not used by the current installed recognition models. Sign training used user-provided recordings processed locally. Private clips are not included in the repository.

## Local execution and internet requirements

Camera tracking, bundled sign inference, message editing and bundled Piper synthesis run on the iPhone without cloud AI calls. Captions explicitly require on-device recognition and do not silently use server transcription, but availability depends on the phone's English recognition assets. Lifeprint reference pages require internet. No backend, account, application API key or saved conversation history is used. Codex/Gemini are development tools, not runtime dependencies.

Local inference keeps conversation processing on the device and lets the core camera-to-reviewed-message-to-voice workflow operate without connectivity or per-message cloud inference charges. Local execution does not establish recognition accuracy.

## Verification and limitations

The user confirmed live fingerspelling, Hello, Thank you and continuous captions on their iPhone. The small sign dataset does not establish general accuracy; Thank you has known ordinary-movement false positives. Spell and Signs remain separate modes. Users review drafts before tapping Speak. No general ASL sentence translator or speech-trigger gesture is implemented.

Offline voice device and simulator builds passed, and simulator inference generated real audio. The update was installed and launched on the iPhone. Phone playback and airplane-mode success have not yet been reported. Fresh judge devices need offline caption availability checked.

## Licensing

See ../THIRD_PARTY_NOTICES.md. sherpa-onnx is Apache-2.0; ONNX Runtime is MIT. The Piper model card identifies the LJ Speech training dataset as public domain. The linked eSpeak NG phonemizer is GPL-3.0-or-later. Corresponding-source and other redistribution obligations remain unresolved for the combined app; retaining notices alone is insufficient. No App Store licensing clearance is claimed.

Dependency binaries and downloadable voice/phonemizer data are excluded from the public repo. Run scripts/setup-offline-voice.sh to retrieve the pinned assets directly from upstream before building. The SignAlphaSet contact sheet is a resized derivative of its cited CC BY 4.0 dataset and is documented in SignAlphaSet-Experiment.md; its model is not shipped.
