# SignAlphaSet video experiment

Source: https://data.mendeley.com/datasets/8fmvr9m98w/3
DOI: 10.17632/8fmvr9m98w.3
Authors: Bindu Garg, Manisha Kasar, Achyut Kashyap, Amber Vats, Gunjan Sharma, Aditya Hange (2025).
Published license: Creative Commons Attribution 4.0 International (CC BY 4.0).

Downloaded original video members only from ASL_dynamic.zip. Five word folders: HELLO (10), THANKYOU (10), SORRY (10), YES (5), NO (5). Actual archive therefore differs from the description claiming ten clips per gesture. No My or Name folders.

Converted AVI/MPEG4 videos to MP4/H.264 with no audio to support Apple's video reader. Original clips preserved in scratch storage. Split by complete clip: 7 training and 3 test clips for the ten-clip labels; 3 training and 2 test for the five-clip labels. No frames from test clips included in training.

This is a small feasibility experiment. Recording independence, signer diversity, linguistic correctness and live recognition on Sophia remain unverified. Scores on these clips cannot establish real-world accuracy. Model has no idle/transition class; it must not be used to automatically append words during a continuous conversation without further rejection testing. Existing fingerspelling app remains unchanged.

## Result

Local MLHandActionClassifier: 40 iterations, batch size 8, prediction window 30 frames at 15 fps, no validation used for tuning. Trained on 27 clips; evaluated on 13 complete held-out clips. Model input: Float32 poses (30, 3, 21); output label and labelProbabilities.

Held-out results: Hello 1/3 correct; ThankYou 3/3; Sorry 3/3; Yes 1/2; No 0/2. Total 8/13 (61.54%). Training accuracy was 100%, which did not generalize to the held-out clips. No independent signer test or live phone evaluation conducted.

Visual spot check: sampled clips show the same signer, Sorry is sideways, and sampled ThankYou frames resemble a temple salute like Hello. This is a concern about labeling that requires confirmation by an ASL signer, not a definitive linguistic assessment. Dataset does not pass the current app integration gate.

The experimental model and full processing logs remain in workspace scratch storage. No model shipped in the app. Sample contact sheet: assets/SignAlphaSet-samples.jpg. Each row is the 20%, 50%, and 80% timestamp of that label's first clip. Frames extracted and resized from the cited CC BY 4.0 source.
