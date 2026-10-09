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

## Roboflow attempt
Selected the raw version 2 of asl-dataset/asl-dataset-p9yw8 to inspect original images rather than augmented copies. Download reached a login gate: “Login or create a free account”; continuing indicates acceptance of Roboflow Terms of Service and Privacy Policy. No account was created, no dataset downloaded, and no word model trained. User sign-in is required to continue the export. Public overview lists Yes and No among 18 labels and a Public Domain license; training suitability remains unverified.

## Local Roboflow experiment — 2026-10-09

User supplied `ASL Dataset.v2-v1-raw-with-validation-set.createml.zip` in Downloads. Extracted into workspace scratch storage. Export contains 153 training, 45 validation, and 23 test still images with object detection annotations, 18 labels. Yes has 6 training / 4 validation / 1 test images; No has 10 training / 0 validation / 1 test images.

Ran Apple's MLHandPoseClassifier locally for 30 iterations, batch size 8, original training split, no validation used in training. Labels were Yes, No, and Other (remaining 16 signs). Original test split was held out. Model saved only in scratch storage and NOT added to the app.

Result: both target test examples were incorrectly classified as Other. All 23 test predictions were Other. Overall 91.30% accuracy reflects class imbalance (21 Other examples) and is not usable target recognition accuracy. Target recall was 0/1 for each class. This small experiment does not establish that the dataset cannot work with another training approach; it establishes that this trained model must not be shipped or presented as word recognition. No live phone word recognition was tested. Static images also cannot validate ASL motion recognition.

Keep working fingerspelling, editable drafts, explicit Speak, and hearing-person captions. A next experiment requires balanced training plus a larger independent target test set, or moving-sign clips with held-out recordings.
