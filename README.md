# ASL Bridge

An iPhone hackathon prototype that helps a Deaf ASL user compose a reviewed spoken message and read a hearing person's reply as live captions. Camera recognition and speech generation run locally on the phone.

## Try it on an iPhone

1. Clone this repository on a Mac with Xcode 27 installed.
2. From the repository folder, run `bash scripts/setup-offline-voice.sh`. This downloads the pinned speech runtime and voice from upstream and checks their SHA-256 hashes. Internet is needed for this one-time build setup.
3. Open `ASLBridge.xcodeproj`. For iOS 18 or newer, connect and trust your iPhone, enable Developer Mode, select your own team under **Signing & Capabilities**, and change the bundle identifier to a unique value. Select your phone and Run. TestFlight is not required.
4. Select **Spell**, turn on the camera and hold a letter steadily. Letters are added automatically. Lower your hand briefly before repeating a letter. Use **Space**, delete, or tap the message to edit. Review it, then tap **Speak**.
5. Select **Signs (Test)** to try **Hello** and **Thank you**. Keep your face, whole hand and wrist visible. These experimental predictions also go into the editable draft.
6. Tap the microphone to start/pause live captions. The app pauses transcription while speaking its own audio and resumes afterward. **Listen** offers a larger caption view.

A simulator can build and test typing/UI/voice; physical iPhone camera input is needed for live sign recognition. Grant camera, microphone and speech permissions when requested.

## What runs locally

Apple Vision tracks hands/face. Core ML runs the bundled alphabet and experimental sign models. Piper generates speech locally using sherpa-onnx and ONNX Runtime. Apple Speech is explicitly configured for on-device English transcription, where the phone supports it and has the necessary recognition assets. The app does not silently fall back to cloud transcription.

There is no backend, application API key, account or conversation upload. Library reference pages from Lifeprint need internet. Building initially needs internet for the setup script. Fresh judge phones must be checked for offline caption support.

Local AI supports private conversation processing and the camera-to-reviewed-message-to-voice workflow without continuous internet or per-message cloud inference charges.

## Models, reuse and development tools

The pretrained `ASLHandPoseClassifier17.mlmodel` comes from [liudasbar/ASL-Recognizer](https://github.com/liudasbar/ASL-Recognizer), whose camera-first layout also informed the UI. Its MIT notice is preserved in [LICENSE-upstream.md](LICENSE-upstream.md). Hello and the experimental face-relative Thank you models were trained locally during the hackathon with user-provided recordings. Private clips are excluded from this repository. Roboflow, WLASL and Google datasets were explored/discussed but are not used by the installed recognition models.

The native application uses Swift, SwiftUI, AVFoundation/AVFAudio, Vision, Core ML, Speech, Foundation, Combine, OSLog and SafariServices. Create ML was used for model training. Offline speech uses the pretrained int8 Piper `en_US-ljspeech-medium` voice, sherpa-onnx 1.13.8, ONNX Runtime 1.28.2 and eSpeak NG. Codex assisted development and debugging; Gemini advice was supplied by the user. UI/UX Pro Max and Web Design Guidelines skills informed design work. These development tools are not runtime dependencies.

See [full disclosures](docs/Hackathon-Disclosure.md), [third-party notices](THIRD_PARTY_NOTICES.md) and [submission checklist](docs/Submission-Checklist.md).

## Hackathon contributions

SwiftUI conversation interface; automatic stable letter capture and repeat controls; editable reviewed draft; continuous caption restart handling; caption pause/resume around speech; camera lifecycle and empty state; training-clip recording; custom Hello/Thank you experiments; bundled offline neural voice integration.

## Limits and verification

This is a prototype, not an unrestricted conversational ASL translator. Spell and Signs are separate modes. Thank you can mistake ordinary movements for signs; the small training dataset does not establish accuracy across signers. J/Z involve motion and may need manual entry. Review every draft before speaking.

The user confirmed letters, Hello, Thank you and continuous captions on their iPhone. Offline voice generated real audio in a simulator; device/simulator builds passed and the new build was installed. Phone voice playback and airplane-mode success have not yet been reported. No broad accuracy or iPhone latency benchmark is claimed.

## Build and tests

Run the setup script before these build commands:

```sh
xcodebuild -project ASLBridge.xcodeproj -scheme ASLBridge -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/aslbridge-build CODE_SIGNING_ALLOWED=NO build
swift test --package-path Core --scratch-path /private/tmp/aslbridge-core-tests
```

Use derived data outside iCloud-synced Documents to avoid signing problems from Finder metadata.

## Distribution and licenses

Runtime binaries, the downloadable voice model and eSpeak data are fetched directly from upstream, rather than redistributed in this repository. Copyright/license notices and the upstream Swift wrapper are included. eSpeak NG is GPL-3.0-or-later; distributing a compiled app requires resolving its corresponding-source and other licensing obligations. This repository does not provide App Store clearance or a compiled app release.

## Submission details still to add

- Official team name and registered members.
- Demo video of one minute or less.
- X or LinkedIn video-post URL with the required sponsor tag and event hashtag.

These details must also be entered in the hackathon submission form. Publishing this repo does not submit the project.
