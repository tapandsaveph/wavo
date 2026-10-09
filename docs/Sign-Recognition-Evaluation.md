# Word-sign feasibility

Status: not implemented or validated.

The reused model classifies individual alphabet/number hand poses; the new UI accepts alphabet labels only. No trained word-sign model or approved training recordings were supplied.

Apple's Hand Action Classification requires temporal examples for moving signs: https://developer.apple.com/videos/play/wwdc2021/10039/
WLASL is a potential video dataset, not a drop-in Core ML hand-keypoint model. Its dataset usage terms and downloaded video availability must be checked before adoption: https://github.com/dxli94/WLASL

Current release decision: ship actual fingerspelling-to-speech and speech captions, with clearly labeled reference-only word signs. Do not replace alphabet labels with phrases or trigger the demo script from arbitrary gestures.

To add 3–5 signs: obtain permitted signer recordings/background transitions, train a matching temporal classifier, test separate trials on the user's phone and with Sophia, measure confusion and false positives, and update the catalog only after validation. No accuracy is claimed without these trials.

## Dataset investigation — October 9, 2026
User selected an existing permitted dataset rather than signer-recorded training clips.

WLASL metadata contains 22 No examples (15 training, 4 validation, 3 test), 22 Yes examples (15/4/3), 14 Thank you examples (10/2/2), and 13 Hello examples (9/2/2). These are metadata counts, not counts of downloaded usable clips.

HEAD checks found accessible MP4/octet-stream sources for all four words. Other URLs returned 403, 404, HTML instead of video, or a certificate mismatch; those sources must not be treated as usable clips. No certificate warnings were bypassed.

The repository explicitly requires reading and agreeing to C-UDA before dataset use; it describes the data as academic/computational use only with no commercial use. Training recordings have not been downloaded or used while this agreement remains pending. The C-UDA distinguishes computational use/trained model results from redistributing raw training data; dataset clips should not be substituted for permitted library media.

ASL Citizen was also investigated: official download is 42.8 GB and has separate Microsoft research terms, with redistribution restrictions. It is not selected for the current hackathon attempt.

Next step after dataset terms are accepted: download the accessible subset, verify decoded video content and split/signers, train a temporal model, and test held-out clips plus real phone trials. Accessible links alone do not establish sufficient examples or usable recognition accuracy.
