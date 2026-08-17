---
name: app-release
description: Prepare an app release, proceeding through diff review against the previous release, proposing the next version and confirming with the user, updating version and build numbers, organizing the CHANGELOG and store release notes, and test and build verification. Use when asked to release the app, prepare a release, submit to the App Store or TestFlight, bump the version, or update the version. Perform commits, tags, pushes, uploads, review submission, and publication only within the requested scope.
---

# Release the app

Determine the release target from the repository's actual state. Keep version selection as a human decision point: present candidates with rationale and always confirm before proceeding.

## 1. Establish the current state and conventions

1. Check `git status -sb`, the current branch, the latest commit, and the latest reachable release tag. Classify uncommitted and untracked changes by origin, and preserve unrelated changes.
2. Read `AGENTS.md`, the README, the release procedure, `CHANGELOG.md`, the store release notes, and the project configuration. Treat existing files and commands as authoritative; do not reuse version numbers or procedures from past work.
3. Review the commits and diffs from the previous release tag to `HEAD`. Cross-check against the CHANGELOG's unreleased entries and confirm, one by one, the user-facing changes that remain for this release. Exclude features reverted after implementation, internal refactors, tests, and developer-only changes from the release entries.
4. Identify the marketing version, the build number, all targets that carry them, any version-bump scripts, and the verification commands.

Completion criteria: you can explain the current version, the previous release, the user-facing changes remaining for this release, every location where version numbers are updated, and the repository-specific verification methods.

## 2. Propose the next version and confirm

Apply the following criteria to both the CHANGELOG and the actual diff. When multiple apply, recommend the largest change.

- **Major**: compatibility-breaking changes, changes requiring migration of existing data or usage patterns, changes that switch the product generation.
- **Minor**: backward-compatible new features, new usage scenarios, user-recognizable feature expansions.
- **Patch**: bug fixes, display/wording/performance improvements, small tweaks to existing features.

If the unreleased entries are empty and there is no diff since the previous tag, recommend holding the release rather than bumping the version. Offer a patch version as a candidate only if the user needs to release without changes.

Present the candidate with a short rationale, e.g. "Currently `1.1.1`, and since the changes are ○○, I recommend patch `1.1.2`." Then ask the user which digit to bump, or for the exact next version. If the CHANGELOG is ambiguous, investigate the diff further before proposing; do not pick a version on guesswork alone.

Do not modify version-related files until the user explicitly chooses the next version. A clear agreement with the presented candidate, such as "go with that" or "yes," counts as a selection.

Completion criteria: the next marketing version is uniquely determined by the user's answer.

## 3. Prepare the release contents

1. Following the repository's rules, update the marketing version and build number across all targets. If the build number convention cannot be determined from existing values or history, present candidates and confirm.
2. Move the CHANGELOG's unreleased entries to the finalized version. Match the heading, date, categories, and the next unreleased section to the existing format and repository rules.
3. Write the store release notes from only the user-facing changes delivered in this release. Use concise natural prose or short bullet points; do not include internal implementation, tests, development procedures, explanations of the subscription system, or app-wide overviews. If those are needed, move them to a separate document that fits their role.
4. If specific versions are pinned in the release procedure or checklist, update only the parts still valid for this release.
5. Re-check the diff and confirm nothing besides the selected version and release target has been mixed in.

Completion criteria: the versions match across all targets, and the CHANGELOG and release notes represent this release's actual diff exactly, with nothing missing or extra.

## 4. Verify

In the order defined by the repository, run the relevant tests, the full test suite, a Release build or archive, and `git diff --check`. Run only available verifications, and record any skipped ones with reasons.

Re-extract the marketing version and build number from the build artifact or generated configuration; do not rely solely on checking the source configuration. Also reconfirm that each release note item actually exists in the target version.

Completion criteria: you can distinguish and explain the evidence of successful verifications performed, the version number consistency, and the unperformed items with remaining risks.

## 5. Proceed as far as requested

- For a release **preparation** request, complete the local version updates, documentation, and verification.
- If commits or pushes are requested, follow the repository's review and commit procedures.
- Tags, artifact uploads, submission to TestFlight/App Store, and publication: perform only the operations and destinations explicitly stated in the request. Reconfirm the target version, build number, and destination before each operation.
- After confirming publication via external state, if the repository rules require it, create the unreleased section for the next patch version and handle it as a separate commit.

## Report

Report the following briefly, separated:

- The finalized marketing version and build number
- The user-facing changes put in the CHANGELOG and release notes
- The results of tests, the Release build, and version number cross-checks
- The status of each of: commit, tag, push, upload, review submission, publication
- Unperformed manual checks and remaining risks

If later-stage operations were not performed, do not describe the app as released, submitted, or published.
