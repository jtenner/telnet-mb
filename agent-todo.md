# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 18, differential checks against a simple reference model, on 2026-05-24.
- Added a test-only, intentionally dumb TELNET core reference scanner for data, escaped `IAC`, simple commands, negotiation triplets, subnegotiation boundaries, and a few basic malformed boundaries.
- Added deterministic differential tests for hand-picked edge seeds and 48 generated complete core streams under a Preserve-CR, generous-cap parser config.
- Documented reference limitations in code: it does not model capacity/discard policy or NVT CR rules.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 19 (broader fuzz documentation), slice 20 (regression backlog cleanup), slice 21 (helper deduplication research), and slice 22 (native coverage-guided fuzzer validation/persistent or file-input modes).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - Hand-picked differential seeds use IDs `17000` through `17011` for empty, data, escaped-IAC, command, negotiation, subnegotiation, and malformed-boundary cases.
  - Generated complete core streams use seeds `18000 + iteration * 173` for iterations `0..47`, with `1 + iteration % 18` generation steps.
- Commands run:
  - `git status --short && printf '\n--- recent commits ---\n' && git log --oneline -8`
  - `moon test`: initially failed on invalid `_` loop variable syntax in new generator; fixed before continuing.
  - `moon test`: 876 tests passed.
  - `git diff -- telnet_fuzz_test.mbt agent-todo.md | sed -n '1,260p'`
  - `moon info && moon fmt`: no public API diff intended.
  - `moon test`: 876 tests passed.
  - `moon info && moon fmt && moon test`: final verification passed with 876 tests.
  - `git status --short && printf '\n--- mbti diff ---\n' && git diff -- pkg.generated.mbti cmd/fuzz/pkg.generated.mbti cmd/fuzz-native/pkg.generated.mbti`
  - `git diff --check`: initially flagged generated `.mbti` blank lines at EOF after each `moon info`.
  - `python3 - <<'PY' ... PY && git diff --check && git status --short`: normalized generated `.mbti` files back to no diff; whitespace check passed.

## Active work slices

### 19. Fuzz documentation

- Add or update `docs/wiki/` with a fuzzing/testing page or section:
  - what properties are tested
  - how to run fast fuzz tests
  - how to run long fuzz tests
  - how to reproduce failures (build on the slice 13 note now in `06-testing-compliance.md`)
  - how to add new seeds/regressions
- Link to relevant TELNET protocol docs already used by the wiki.

Acceptance criteria:

- Documentation is accurate and command examples work.
- Any protocol claims cite existing source docs or authoritative URLs.

### 20. Regression backlog cleanup

- Search TODOs, skipped tests, and comments created during fuzzing.
- Convert known failures into either fixed bugs or explicit documented limitations.
- Remove dead experiments and unused helpers.

Acceptance criteria:

- No unexplained TODOs or skipped fuzz tests remain.
- `moon info && moon fmt && moon test` passes.

### 21. Shared fuzzer helper research

- Investigate whether deterministic RNG, TELNET-biased input generation, observation normalization, and failure formatting can be shared between `telnet_fuzz_test.mbt` and `cmd/fuzz` without exposing test-only API from the public package.
- If MoonBit package boundaries make sharing awkward, document the duplication and keep command/test helpers intentionally independent.
- Preserve fast default tests and keep `cmd/fuzz` runnable.

Acceptance criteria:

- Helper drift risk is reduced or explicitly documented.
- No public TELNET API is added solely for fuzz internals.


### 22. Native coverage-guided fuzzer validation

- Run the `cmd/fuzz-native` harness with an installed coverage-guided engine, preferably AFL++ via `CC=afl-clang-fast tools/build-fuzz-native.sh`, and record any required command refinements.
- If honggfuzz support is worthwhile, add a file-path input mode or checked wrapper rather than relying on undocumented shell redirection.
- Consider a persistent/in-process C shim only if it can stay isolated from the public TELNET API and normal tests.

Acceptance criteria:

- At least one coverage-guided engine command is validated end-to-end or blockers are documented.
- Any crash is reduced to a named deterministic regression test.
- Default `moon test` behavior remains fast and deterministic.

## Suggested recurring-agent loop

For each cron run:

1. Read this file and `AGENTS.md`.
2. Inspect repository state and recent changes.
3. Add or refine only active todo tasks when new meaningful fuzzer work is discovered.
4. Pick the highest-value incomplete slice that can be finished in one run.
5. Implement tests first when practical.
6. Fix discovered bugs or document limitations.
7. Run `moon info && moon fmt` and `moon test`.
8. Remove completed tasks from this file; keep only remaining active work.
9. Commit the completed work.
