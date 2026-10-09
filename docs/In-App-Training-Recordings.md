# Record examples on the iPhone

Open Conversation, choose Thank You (Test), and Start Camera. Expand Record examples for the model. Choose the label and Training or Testing, then Record 3-second clip. Record one natural complete sign while keeping face, hand and wrist visible. Recording pauses recognition and does not add text or speak. Wait for Clip saved before the next clip. Share saved clip exports the latest recording using the standard share sheet.

Record a first clip and verify that it saves and plays upright before a larger batch. Suggested first batch: eight Thank you Training recordings and three separate Thank you Testing recordings. Ordinary movement examples can use the same controls, with the corresponding label. Testing clips must stay out of training.

Clips use the app's front camera and are stored without audio in the app Documents/TrainingClips/{train,test}/{ThankYou,Hello,Other}. Filenames include split, class and a UUID. Existing clips remain on the phone; Share saved clip exposes only the latest completed file. No external upload or automatic training is performed. Incomplete clips are discarded when camera recording is interrupted. Keep original completed recordings for labeling and retraining provenance; do not add private videos to the public hackathon repository.

Verification: device build passed; 13 core tests passed. Installation and launch are separate from live capture verification. Actual recording, orientation, simultaneous video-output compatibility, share export, interruption behavior and fresh recognition must be verified on the physical phone before claiming the workflow is validated.
