# Hello recognition experiment

Local user-provided recordings, 2026-10-09. No clips uploaded to an external service or added to the app repository.

Source of truth for labels: user explicitly identified IMG_1906–IMG_1922 as Hello training, IMG_1923–IMG_1924 as Hello testing, and IMG_1925–IMG_1933 plus IMG_1924 2 as Other.

IMG_1924 2.MOV has exactly the same SHA-256 as IMG_1924.MOV, a Hello test recording. Excluded duplicate from Other to avoid conflicting labels and test leakage. Original files preserved.

Training: 17 Hello clips, six Other clips (IMG_1925–IMG_1930). Test: two Hello clips (IMG_1923–IMG_1924), three Other clips (IMG_1931–IMG_1933). Entire clips held out, no training on test frames. Train/test SHA-256 disjointness checked in preparation.

Videos converted locally to H.264 MP4, orientation applied, audio removed and width resized to 720 for feature extraction. Original clips remain in Downloads. Scratch manifest preserves original source paths, labels, splits and hashes.

Model: Apple's MLHandActionClassifier, 40 iterations, batch size 8, 15-frame prediction window, target rate 15 fps, no validation tuning. This is an initial user-specific feasibility experiment, not validated general ASL translation. Two Hello test clips cannot establish general accuracy. Some training closeups have partially cropped hands. Live phone results remain unverified.

## First model results

Create ML held-out evaluation: 4/5 clips correct (80%); Hello 2/2, Other 2/3. The held-out hair-adjustment clip IMG_1931 was falsely classified as Hello. This tiny same-person evaluation does not establish general accuracy.

Per-window predictions are more concerning than clip aggregate accuracy: IMG_1931 includes Hello scores of 0.903 and 0.916; IMG_1932 has multiple Hello-scored windows as well. A nominal 0.85 cutoff cannot safely reject these. Repeated 0.903 scores appear in missing-hand windows, suggesting empty/padded pose inputs also need explicit rejection. No live app integration was performed.

The six Other training clips are primarily bottle/drinking movements; testing includes different near-face actions. Next data collection should include varied near-face movements as training negatives, plus fresh independent testing clips. Do not add the current held-out tests to training and continue calling their results independent. Do not tune confidence on these five tests and report a general accuracy claim.

Experimental model remains in work/user-hello-actions/HelloExperimental.mlmodel. Existing app remains unchanged. Next integration needs real-hand presence checks, transition/duplicate controls, user draft review and a new live test, in addition to more representative negative examples.

## Second model: additional ordinary movements

Added five new user-provided videos IMG_1942–IMG_1946 as Other training examples, including hair, glasses and near-face movements. IMG_1939.HEIC and IMG_1941.HEIC are still photos and were excluded from video training. All originals preserved. Preparation verified no exact duplicate hashes or overlap between training and test clips.

Training now contains 17 Hello and 11 Other clips. Same model parameters; all five original tests remain excluded from training. This is a development retest informed by earlier errors, not fresh independent validation.

Create ML clip evaluation remains 4/5 (80%), but the errors changed: Hello 1/2, Other 3/3. Every reported window in the three Other test clips now predicts Other. Both Hello clips contain a Hello window with confidence 1.0, but IMG_1923 begins with an uncertain window (Hello 0.496, Other 0.504); clip-level evaluation marks it incorrect. This supports investigating live temporal detection, but does not establish reliable recognition or justify an accuracy claim from five examples.

Second experimental model remains in work/user-hello-actions-v2/HelloExperimental.mlmodel. No app integration or phone validation performed. Before live use, reject missing-hand input, preserve explicit draft review, and test fresh Hello and varied ordinary movements on the phone.
