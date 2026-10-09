# Execution ledger — ASL Bridge implementation plan

- Plan and PRD approved in chat; user selected inline execution.
- Ruling: independent project folder is the isolated implementation workspace; upstream probe is preserved.
- Ruling: build scratch moved to /private/tmp after iCloud metadata caused codesigning failures under Documents. App source remains in outputs.
- Ruling: core tests share the actual message/audio state file through a relative symlink, avoiding duplicate business logic.
- Ruling: word-sign library opens verified original reference pages. No media redistribution permissions or validated temporal word model are available yet; camera recognition remains alphabet-only. Bundled videos and whole-word recognition remain unfulfilled follow-up milestones, not completed features.
- Core tests initially failed because the required message/candidate/audio types were absent.
- Simulator app build succeeded; physical device speech and camera testing pending.
- Three shared-core tests pass; new app builds for simulator and physical iPhone, installs, and launches.
- Independent reviewer found a partial camera configuration retry risk; moved canAdd checks before input/output mutation. Speech completion also checks current speaking activity to avoid clearing listening state.
- Simulator visual inspection led to a compact navigation title and a shorter camera preview to bring message actions closer to view.
- Remaining: physical end-to-end checks by user/Sophia, permitted bundled videos, optional word-sign model, demo recording, and GitHub destination. These are not marked complete.
