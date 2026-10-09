# ASL Bridge

Native iPhone hackathon prototype for exchanging messages between a Deaf ASL user and a hearing person.

## Try it
1. Open `ASLBridge.xcodeproj` in Xcode 27.
2. For the simulator, choose an iPhone simulator and Run. Camera recognition requires a physical iPhone.
3. For a physical phone running iOS 18 or newer: connect and trust the phone, enable Developer Mode, select your Personal Team under Signing & Capabilities, and change the bundle identifier to a unique value. Select the phone and Run.
4. In **Spell**, tap Start Camera, hold one alphabet pose, check the candidate letter, and tap Add Letter. Repeat; use Space/Delete or edit the message directly. Tap Speak Message to read the reviewed text aloud.
5. In **Listen**, tap Start Listening and grant microphone/speech permissions. Speak an English reply; captions appear. Tap Stop Listening. Captions can also be typed.
6. Library opens original ASL University reference pages in your browser. These references require internet; no signing videos are bundled.

## What works and what is limited
- Bundled alphabet hand-pose recognition, explicit letter capture, editable message, native speech synthesis, on-device English speech recognition when supported, and reference links.
- This is not a continuous ASL translator. No word-sign recognition model is installed. J and Z involve movement and may require manual entry. Accuracy varies with signer, pose, lighting, and camera angle.
- A model probability is not a guarantee of correctness. Always review the message before speaking.
- Speech permission and on-device recognition availability must be checked on each device. The app offers typing if offline recognition is unavailable; it does not silently fall back to server transcription.
- No account, backend, API key, camera/audio uploads, or saved conversation history.

## Build and tests
```sh
xcodebuild -project ASLBridge.xcodeproj -scheme ASLBridge -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
swift test --package-path Core --scratch-path /private/tmp/aslbridge-core-tests
```
If Documents is synced with iCloud, place derived build data outside that synced directory using `-derivedDataPath /private/tmp/aslbridge-build`. Finder metadata in build bundles can interfere with signing.

## Hackathon work and attribution
The SwiftUI UI, camera lifecycle, reviewed letter capture, model probability gating, speech/caption flow, message/audio tests, and reference catalog were built during this hackathon. The pretrained `ASLHandPoseClassifier17.mlmodel` is inherited from [liudasbar/ASL-Recognizer](https://github.com/liudasbar/ASL-Recognizer). Its MIT notice is preserved in `LICENSE-upstream.md`. The upstream author did not provide the training dataset; this project has not independently established that dataset's provenance or broad model accuracy.

ASL University reference links belong to William G. Vicars / Lifeprint. Their media is not copied into this project. See `THIRD_PARTY_NOTICES.md` and `docs/Verification.md`.
