# Verification — October 9, 2026

## Confirmed
- Upstream alphabet recognizer was installed on iPhone 14 Pro Max (iOS 18.7.8); user reported it recognizes letters.
- New ASL Bridge project builds for the iOS simulator and physical iPhone using Xcode 27.
- New app installed and launched on the physical iPhone using the user's Personal Team.
- Simulator initial screen was rendered and inspected.
- Three Swift Testing tests pass against the app's shared message/audio state: repeated letters/corrections, rejected stale/uncertain/invalid candidates, and exclusive audio activity.
- Independent read-only review checked model input/output contract, prediction expiry, microphone/playback ordering, and recognition generation guards. A partial camera-configuration retry issue was fixed by checking both additions before mutating the session.

## Not yet confirmed on the new app
- Sophia's live alphabet recognition across lighting/angles and repeat-letter capture.
- Real spoken caption recognition and speech synthesis playback.
- Permission-denial recovery, backgrounding, audio interruption, and feedback behavior on device.
- VoiceOver/Dynamic Type device checks and library-link playback in the browser.
- No word-sign recognition, bundled signing videos, or continuous ASL translation was implemented or claimed.
- No submission repository has been published; destination is not yet chosen.

Tests of AudioActivity alone are not tests of Apple's capture/recognition services. Device checks remain necessary.

## Library update
- User confirmed new app letter capture, speech playback, and captions work.
- Five shared-core tests pass, including exact caption matching, search aliases, unique vocabulary IDs, and honest recognition availability.
- Library references for Hello, Name, Thank you, Yes, and No were opened and verified at their original source.
- Updated physical-device build succeeds; app installs and launches. User playback checks of the in-app reference pages are pending.
- WLASL terms and target-word sample metadata were inspected; no word-sign training has occurred.

## Letter stability update
Eight core tests pass, including full-window gating, eight confident matches out of ten, split predictions, low-confidence current frames, missing hands, stale observations and time gaps. Physical iPhone build succeeded. Live recognition accuracy still requires user testing; temporal consistency does not correct consistently wrong model predictions.

## Capture behavior
Manual Add Letter remains intentional during validation. Each tap adds the currently ready letter, allowing repeated letters. There is no automatic append or speech. Camera history resets when the hand disappears, capture fails, or the session stops/restarts. Native text autocorrection is disabled in the draft to preserve intended names and words.

## Faster automatic capture (supersedes manual stability behavior above)
Eight core tests pass. Capture now requires an uninterrupted confident same-letter hold of at least 0.45 seconds. Each held letter emits once; a different stable letter or at least 0.3 seconds of observed hand absence allows the next capture. Uncertain predictions and capture errors interrupt the hold without rearming duplicates. Speech remains explicitly triggered. Physical iPhone build succeeded; live speed and accuracy need user validation.
