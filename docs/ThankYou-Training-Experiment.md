# Thank you experiment — 2026-10-09

Training labels supplied by the user. Fourteen ThankYou clips: IMG_1948, IMG_1949, IMG_1953–IMG_1964. Combined with previous 17 Hello and 11 Other training clips. Tests: four new ThankYou clips IMG_1965–IMG_1968, two previous Hello and three previous Other tests. IMG_1963 2 and IMG_1964 2 were excluded because their hashes match training clips. Originals preserved; no video uploads or private recordings added to the repository.

Apple MLHandActionClassifier: 40 iterations, batch size 8, 15-frame window, 15 fps, no validation tuning. Export in scratch work/user-word-actions/WordGesturesExperimental.mlmodel.

Clip-level evaluation: 5/9 correct. Hello 2/2; ThankYou 1/4; Other 2/3. One ordinary-movement test was classified ThankYou. These same-person, small development tests do not establish general accuracy.

Replay with the live hand-quality rule and rolling 15-frame windows: IMG_1966 and IMG_1967 each provided only two qualifying hand frames; IMG_1968 five. None reached the nine tracked frames required for inference. IMG_1965 has ordinary actions before its sign; its qualifying windows scored ThankYou at most 0.026. Thus both hand tracking and model discrimination need work. Contact-sheet inspection shows the signer relatively small in frame, fingers together near the face, and some fast motion; these are plausible contributors, not proven sole causes.

Do not replace the working Hello model with this export. Next collect closer, well-lit full-hand examples, with the complete natural movement visible, and separate fresh testing. Keep the existing phone build unchanged.

## Second training run

User explicitly assigned IMG_1969–IMG_1972 to training. Added four unique originals after SHA-256 duplication and split checks. Training now 18 ThankYou, 17 Hello, 11 Other; original nine tests unchanged. Same parameters as the first run, exported separately under work/user-word-actions-v2.

Clip-level development retest: 7/9 correct (77.78%). ThankYou improved from 1/4 to 3/4; Hello 2/2; Other 2/3 with one false ThankYou. Reusing these tests after observing errors is development evaluation, not fresh independent validation. The old fast/far test clips still have insufficient quality-tracked frames for live admission in three cases. Do not claim that clip classification implies the live pipeline recognizes them. Phone app remains the confirmed Hello-only build. Next need fresh closer ThankYou testing and further ordinary-movement testing before installation.

## User-authorized reassignment of ThankYou tests

The user explicitly requested moving IMG_1965–IMG_1968 into training. Version 3 contains 22 ThankYou training clips. Previous versions and original recordings are preserved, but these four clips are now seen data and cannot establish independent ThankYou accuracy for version 3. No held-out ThankYou clips remain. Hello and Other test clips remain separate. Fresh live gestures or fresh recordings are required for ThankYou validation.

## Live regression and rollback

The user reported neither sign detecting after installation. Version 3 replay through rolling-window admission produced peak Hello scores 0.118 and 0.790 on original Hello tests, below the unchanged 0.9 gate. This confirms a regression concealed by aggregate clip evaluation. The clearer ThankYou training recording IMG_1972 reaches 0.999, which is seen-data diagnostic evidence only. Its result does not explain the user's live failure; camera status is needed to distinguish tracking/admission from classification. Restored the previously user-confirmed Hello model and Hello-only UI, rebuilt and reinstalled. Do not claim the combined model is validated.

## Dedicated ThankYou classifier experiment

Trained a binary model using all 22 ThankYou training clips and the 17 Hello plus 11 ordinary-movement training clips relabeled Other. Original five held-out Hello/Other negatives stay excluded from training; no positive held-out ThankYou remains. Same 40 iterations, batch 8, window 15, target 15 fps.

Held-out negative clip evaluation: 3/5 rejected, 2/5 false ThankYou. Rolling-window replay with live admission: IMG_1923 (Hello) reaches ThankYou 0.930; IMG_1933 (ordinary face movement) reaches 1.0. IMG_1972 reaches 1.0 but is training data, not independent positive validation. Thus a 0.9 gate does not resolve false positives. Do not install this model; current separate Hello and experimental ThankYou phone build remains unchanged. Model retained locally at work/user-thankyou-binary/ThankYouExperimental.mlmodel for diagnosis.

## In-app recording experiment (v4)

Retrieved seven clips from the iPhone app’s `Documents/TrainingClips/train/ThankYou` directory. Preserved originals on the phone, converted local copies to upright H.264 video, and added them to the existing training split. No new testing recordings were present at retrieval. Dataset: Hello 17, ThankYou 29, Other 11 training clips; existing held-out Hello 2 and Other 3 clips. No held-out ThankYou examples remain from the earlier reassignment requested by the user.

Retrained with the existing 15-frame, 15-fps Create ML hand-action configuration. Training clip accuracy was 89.47%; held-out clip accuracy was 60%, with one ordinary-movement clip mislabeled ThankYou. Approximate app-window replay also reached ThankYou confidence 0.994 on that negative clip (`IMG_1933`). This exceeds the existing 0.90 gate. **The model was not installed:** it still produces a confident false positive. Fresh ThankYou testing and ordinary-movement recordings are needed; additional negative training examples may be needed. Working Hello and the installed app were preserved.

## Additional ordinary movement training (v5)

User authorized reassignment of the three new `test/Other` recordings to training. Earlier six in-app tests remain held out: first three chronological clips are ThankYou, last three Other (confirmed by user despite original folder labels). Training/testing source SHA-256 sets are disjoint. Training has 17 Hello, 29 ThankYou, 14 Other clips.

Retrained with unchanged Create ML parameters. Replay now includes the app’s 0.3-second missing-hand buffer reset and 0.2-second prediction interval, which the earlier approximate replay omitted. It produced a ThankYou confidence above 0.90 in 1/3 fresh ThankYou tests; the other two had insufficient usable tracking windows after buffer resets. The earlier 2/3 claim came from approximate replay and should not be read as exact app capture performance. It still exceeded 0.90 on 1/3 fresh ordinary-movement tests (0.997) and on the older face-movement negative IMG_1933 (1.0). This candidate was rejected and not installed; working Hello model and app were preserved. More negatives alone did not resolve the underlying tracking/window and gesture-confusion issues.

## Tracking diagnosis

Compared app-like replay at missing-hand reset durations 0.3, 0.6 and 1.0 seconds with prediction interval 0.2 seconds unchanged. v5 fresh positive peaks at 0.3 seconds: 0.996, no eligible prediction, no eligible prediction. At both 0.6 and 1.0 seconds: 0.997, 0.897, 0.602. Thus extending the reset did not recover additional positives at the unchanged 0.90 gate. Fresh ordinary-movement false positive remained above 0.99; older face movement remained 1.0. Visual inspection of the upright positive recordings confirms complete gestures, with the hand near the face then moving away and dropping before the end of the clip. Tracking yields only 10 usable sampled frames for two positives. The fixed 15-frame window, tracking gaps, and model confusion are distinct issues. No app timing, confidence thresholds, or models were changed as a result of this failed hypothesis.

These are recorded-clip diagnostic results, not a guarantee of live-device behavior or general ASL accuracy. A combined sign/fingerspelling mode would require separate validation against letters and transitions; running both classifiers together alone is not sufficient.

## Ten-frame recognition experiment

Retrained the unchanged v5 training split with predictionWindowSize 10 (previously 15), keeping 15 fps, 40 iterations and batch size 8. Held-out clips remained separate. Replay used 10 frames, at least six tracked frames, latest frame tracked, the existing 0.3-second missing-hand reset and 0.2-second prediction interval. Fresh ThankYou maximum probabilities were 0.536, 0.526 and 0.449: none met 0.90. Fresh ordinary movement peaks were 0.020, 0.046 and 0.716; none met 0.90. Older negative IMG_1933 still reached 1.0. Shortening the window therefore removed fresh positive detections while retaining an older confident false positive. Rejected; not installed. This result does not justify lowering the confidence threshold or modifying the working Hello pipeline.

## Face-relative hand experiment

Extracted Vision face landmarks and hand joints from the existing upright v5 videos at approximately 10 fps. Each frame includes face/hand availability, tracked-joint fraction, and wrist/thumb/index/middle/ring tip positions relative to the mouth, normalized by face bounding-box dimensions. Missing observations are zero-filled with availability features. Averaged each complete clip into eight temporal bins; trained a Create ML random forest (maxDepth 5, 50 iterations, validation none) on the unchanged training split. No held-out clips were used for fitting.

Held-out whole-clip top-class results: Hello 2/2 correct; ThankYou 3/3 correct; ordinary movement only 2/6 correctly rejected, with 4/6 mislabeled ThankYou. Overall 7/11 (63.64%). These are top-class predictions, not a measured live 90% confidence-gate capture rate. Whole-clip temporal normalization requires known clip boundaries and is not a continuous live recognition implementation. The experiment shows that adding face-relative position alone does not solve ordinary-movement confusion with this small dataset. Model and private features remain in scratch storage; nothing was installed or added to the app. Working Hello/fingerspelling remain unchanged.

## User-authorized live experimental installation

User explicitly accepted recognition mistakes and requested testing the face-aware feature on iPhone. Integrated the experimental random forest into Thank You (Test), retaining working Hello and alphabet models. The existing WordGesturesExperimental resource now contains the face-relative model; its experimental mode consumes 96 binned numeric features, rather than the prior hand-action tensor. Uses a rolling 30-sample sequence with face/hand extraction, a four-second repeat cooldown and editable-draft output only. Shows an explicit warning about ordinary-movement confusion. No automatic speech. Device build succeeded, installed and launched on connected iPhone. Live accuracy remains unverified; rolling-window boundaries and device sampling differ from whole-clip evaluation.
