# Word-sign feasibility

Status: not implemented or validated.

The reused model classifies individual alphabet/number hand poses; the new UI accepts alphabet labels only. No trained word-sign model or approved training recordings were supplied.

Apple's Hand Action Classification requires temporal examples for moving signs: https://developer.apple.com/videos/play/wwdc2021/10039/
WLASL is a potential video dataset, not a drop-in Core ML hand-keypoint model. Its dataset usage terms and downloaded video availability must be checked before adoption: https://github.com/dxli94/WLASL

Current release decision: ship actual fingerspelling-to-speech and speech captions, with clearly labeled reference-only word signs. Do not replace alphabet labels with phrases or trigger the demo script from arbitrary gestures.

To add 3–5 signs: obtain permitted signer recordings/background transitions, train a matching temporal classifier, test separate trials on the user's phone and with Sophia, measure confusion and false positives, and update the catalog only after validation. No accuracy is claimed without these trials.
