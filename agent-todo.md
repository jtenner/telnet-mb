# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 14, separate long-running fuzz command/package, on 2026-05-24.
- Added `cmd/fuzz` as a runnable deterministic fuzzer configurable with positional arguments: seed, iterations, max length, and target (`all`, `smoke`, `streaming`, or `stability`).
- The command exercises parser smoke invariants across representative parser configs, streaming equivalence, and parse/encode stability without changing the fast default `moon test` suite.
- Added `docs/wiki/06-testing-compliance.md` invocation and failure-reproduction notes for `moon run cmd/fuzz`.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 15 (CI-friendly fuzz mode), slice 16 (coverage-guided fuzzing research), slice 17 (performance/allocation guardrails), slice 18 (differential reference checks), slice 19 (broader fuzz documentation), slice 20 (regression backlog cleanup), and slice 21 (helper deduplication research).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - Default command verification used `seed=424242 iterations=1024 max_length=128 target=all` and reported checksum `514624`.
  - Argument parsing/reproduction verification used `seed=7 iterations=8 max_length=16 target=streaming` with checksum `25`, and `seed=11 iterations=8 max_length=16 target=stability` with checksum `48`.
  - Failure lines from the command include `target=... seed=... iteration=... max_length=... wire=bytes([...])` for copying into named regression tests.
- Commands run:
  - `git status --short && echo '--- recent commits ---' && git log --oneline -8`
  - `moon run cmd/fuzz` during implementation: first failed on `moon.pkg` import separator syntax, then failed on command-package `byte(...)`/custom `to_string()` usage; both issues were fixed.
  - `moon run cmd/fuzz` after fixes: passed with checksum `514624`.
  - `moon run cmd/fuzz -- 7 8 16 streaming` during implementation exposed that `@env.args()` includes argv0; argument offset was fixed.
  - `moon run cmd/fuzz -- 7 8 16 streaming`: passed with checksum `25`.
  - `moon info && moon fmt`
  - `git status --short && git diff --stat && git diff -- cmd/fuzz/main.mbt | head -120 && find cmd/fuzz -maxdepth 1 -type f -print -exec ls -l {} \\;`
  - `moon test`: 871 passed.
  - `moon run cmd/fuzz && moon run cmd/fuzz -- 7 8 16 streaming && moon run cmd/fuzz -- 11 8 16 stability && git diff --check`: all fuzz commands passed; `git diff --check` passed.
  - `moon info && moon fmt && moon test && moon run cmd/fuzz -- 7 8 16 streaming && git diff --check && git status --short`: 871 tests passed; streaming command checksum `25`; working tree contained this slice's docs, todo, and `cmd/fuzz` changes.

## Active work slices

### 15. CI-friendly fuzz mode

- Add a moderately larger fuzz run suitable for CI if project CI exists.
- Keep runtime bounded and configurable.
- Ensure failures are deterministic and reproducible.
- Avoid flaky timing-based assertions.

Acceptance criteria:

- CI can run the fuzzer without excessive runtime.
- Local fast tests remain fast.

### 16. Coverage-guided fuzzing research spike

- Investigate whether MoonBit/native output can be connected to AFL++, libFuzzer, honggfuzz, or another coverage-guided engine.
- Prefer documented, repeatable setup over clever one-off scripts.
- If feasible, add an experimental harness under `cmd/fuzz-native/` or `tools/` with clear docs.
- If not feasible, document blockers and keep deterministic property fuzzer as primary approach.

Acceptance criteria:

- Feasibility decision captured in docs.
- No fragile external dependency is required for normal tests.

### 17. Performance and allocation guardrails

- Add fuzz cases with large but bounded payloads and long negotiation streams.
- Assert parser makes progress and avoids pathological response growth.
- Consider benchmark cases in `cmd/bench/` for worst-case byte patterns discovered by fuzzing.

Acceptance criteria:

- Known worst-case patterns are benchmarked or tested.
- No unbounded response amplification for small inputs.

### 18. Differential checks against a simple reference model

- Build a tiny test-only reference scanner for a small subset of TELNET: data bytes, escaped `IAC`, simple commands, and subnegotiation boundaries.
- Compare production parser results against the reference model for that subset.
- Keep reference intentionally dumb and independent from production implementation.

Acceptance criteria:

- Differential property catches parser drift for core framing.
- Reference model limitations are documented.

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
