# Third-party notices

## Alphabet model
Source: https://github.com/liudasbar/ASL-Recognizer
Copyright (c) 2022 Liudas Baronas. MIT license preserved in LICENSE-upstream.md.
Inherited file: ASLBridge/Resources/ASLHandPoseClassifier17.mlmodel.
The repository says its training examples came from multiple internet sources and does not distribute its training dataset. No independent provenance audit is claimed.

## ASL reference pages
https://www.lifeprint.com/ — ASL University, William G. Vicars.
External browser links only. No images or videos copied or redistributed. Signer review of references remains a user validation task.

## Bundled offline speech (2026-10-10)

- sherpa-onnx 1.13.8: Apache-2.0; Swift wrapper pinned to commit 9db1af1871ed78cee9357c23898e5a7d8702d21a. https://github.com/k2-fsa/sherpa-onnx
- ONNX Runtime 1.28.2: MIT. https://github.com/microsoft/onnxruntime
- Piper en_US-ljspeech-medium int8: upstream model card identifies the LJ Speech training dataset as public domain. Model card is included with the voice. https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/ljspeech/medium
- eSpeak NG: GPL-3.0-or-later, including the phonemizer linked into the runtime. License copied into the app resources. Source used by the upstream build: https://github.com/csukuangfj/espeak-ng/tree/ed530aa113046142eb5115cf2fc9157854d0ffe1

Do not describe this combined runtime as exclusively Apache/MIT. Redistribution of the linked app must satisfy the eSpeak NG GPL terms, including corresponding source requirements; these notices alone do not satisfy those requirements. This local hackathon integration has not been reviewed for App Store distribution.

The model, tokens, phonemizer data, and iOS frameworks are bundled; speech synthesis makes no network requests. Temporary generated audio is deleted on completion or cancellation.
