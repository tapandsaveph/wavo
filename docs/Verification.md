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
