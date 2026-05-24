# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 22, native coverage-guided fuzzer validation, on 2026-05-24.
- Added `tools/check-fuzz-native.sh`, a checked native validation helper that builds the native stdin harness, runs the escaped-IAC smoke probe, detects AFL++ tools, and either runs a bounded AFL++ stdin smoke session or reports the missing-engine blocker with install/override guidance.
- Updated `docs/wiki/10-fuzzing.md` with the helper command, environment overrides, and manual AFL++ equivalent.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: none; the fuzzer backlog is complete. Optional external validation can rerun `REQUIRE_AFL=1 tools/check-fuzz-native.sh` on a host with AFL++ installed, but there is no remaining repository task.
- Reproduction seeds/details:
  - Native smoke probe used stdin wire `bytes([255, 255])`, default max input bytes `4096`, checksum `20`.
  - AFL++ and honggfuzz were not installed in this workspace (`afl-fuzz`, `afl-clang-fast`, and `honggfuzz` were not found), so no coverage-guided crash corpus or new deterministic regression seed was produced.
- Commands run:
  - `git status --short && printf '\n--- recent commits ---\n' && git log --oneline -5`
  - `git status --short && printf '\n--- recent details ---\n' && git show --stat --oneline --name-only --no-renames HEAD~3..HEAD`
  - `command -v afl-fuzz || true; command -v afl-clang-fast || true; command -v honggfuzz || true; command -v clang || true; command -v cc || true; ls -la tools/fuzz-corpus/seeds`
  - `tools/check-fuzz-native.sh`: passed non-instrumented native smoke and skipped AFL++ because `afl-fuzz` was missing.
  - `moon info && moon fmt`: passed.
  - `moon test`: passed with 876 tests.
  - `git diff --check`: initially found regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff --check`: normalized generated `.mbti` EOF whitespace and passed whitespace check.
  - `moon info && moon fmt && moon test`: final verification passed with 876 tests after the todo update.
  - `git status --short && printf '\n--- diff stat ---\n' && git diff --stat && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti cmd/fuzz-common/pkg.generated.mbti && printf '\n--- whitespace ---\n' && git diff --check`: final whitespace check again found regenerated blank EOF lines in generated `.mbti` files.
  - `python3 - <<'PY' ... PY && git diff --check`: normalized generated `.mbti` EOF whitespace again and passed final whitespace check.
  - `tools/check-fuzz-native.sh && moon info && moon fmt && moon test`: final rerun passed native smoke, skipped AFL++ because `afl-fuzz` was missing, and passed 876 tests.
  - `bash -n tools/check-fuzz-native.sh && git diff --check`: passed.

## Active work slices

No active fuzzer tasks remain; the fuzzer backlog is complete as of 2026-05-24.

## Suggested recurring-agent loop

The recurring fuzzer-improvement loop can remain disabled while this backlog is complete. Re-enable it only after adding a concrete, independently reviewable active fuzzer task.
