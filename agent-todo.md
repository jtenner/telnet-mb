# Agent TODO: TELNET Fuzzer Active Backlog

Purpose: track only active, incomplete fuzzer-improvement work for this MoonBit TELNET protocol library. Completed tasks, historical run notes, and closed reproduction details should not be kept in this file; they belong in git history, commit messages, tests, or docs.

Before and after code changes, follow `AGENTS.md`: run `moon info && moon fmt` and `moon test`; inspect generated `.mbti` diffs for intended public API changes.

## Backlog policy

- Only active todo tasks should be placed in this file.
- Remove a task from this backlog once it is completed and committed.
- Keep entries concise, actionable, and independently reviewable.
- If a fuzz case exposes a bug, reduce it into a named regression test and keep any long-term follow-up here only if work remains.

## Latest completed slice

- Completed slice 16, experimental native coverage-guided fuzzing, on 2026-05-24.
- Added `cmd/fuzz-native`, a native-only stdin harness for concrete TELNET wire inputs. It runs parser smoke checks across representative configs plus one-byte streaming-equivalence and parse/encode stability checks, and prints `target=... length=... wire=bytes([...])` on failure.
- Added `cmd/fuzz-native/fuzz_stdin.c` for bounded stdin reads without changing the public TELNET API, plus generated package interface metadata.
- Added `tools/build-fuzz-native.sh` to rebuild MoonBit-generated native C with `CC`/`AFL_CC`, and added a tiny seed corpus under `tools/fuzz-corpus/seeds/` for command, negotiation, escaped-IAC, NUL, plain-data, and subnegotiation inputs.
- Documented the feasibility decision in `docs/wiki/06-testing-compliance.md`: AFL++-style process fuzzing is practical through the native generated-C/rspfile path; libFuzzer is not the primary path without an in-process `LLVMFuzzerTestOneInput` shim; honggfuzz should be validated with a file-input mode or wrapper before documenting a stable command.
- No production parser bug was exposed in this slice.
- Remaining follow-ups: continue with slice 17 (performance/allocation guardrails), slice 18 (differential reference checks), slice 19 (broader fuzz documentation), slice 20 (regression backlog cleanup), slice 21 (helper deduplication research), and slice 22 (native coverage-guided fuzzer validation/persistent or file-input modes).
- Reproduction seeds/details:
  - No new fuzz failure seed was discovered.
  - Native harness smoke input `bytes([255, 255])` reported checksum `20` with default `max_input_bytes=4096`.
  - Corpus smoke covered `command-nop.bin`, `escaped-iac.bin`, `negotiation.bin`, `nul.bin`, `plain.bin`, and `subnegotiation.bin` from `tools/fuzz-corpus/seeds/`.
  - Optional standalone native harness was built at `_build/fuzz-native/telnet-fuzz-native` with the default `cc` compiler; use `CC=afl-clang-fast tools/build-fuzz-native.sh` when AFL++ is installed.
- Commands run:
  - `git status --short && printf '\n--- recent commits ---\n' && git log --oneline -5`
  - `moon version || moon --version; moon build --help | head -100; moon run --help | head -100`
  - `git show --stat --oneline HEAD && git show --name-only --oneline HEAD | sed -n '1,120p'`
  - `moon run --target native --build-only cmd/fuzz`
  - `moon run --target native --build-only -v cmd/fuzz`
  - `moon info && moon fmt && printf '\377\377\377\372\030hello\377\360' | moon run --target native cmd/fuzz-native` (initially failed on a loop parse error; fixed before continuing)
  - `moon run --target native --build-only -v cmd/fuzz-native`
  - `tools/build-fuzz-native.sh _build/fuzz-native/telnet-fuzz-native && printf '\377\377' | _build/fuzz-native/telnet-fuzz-native && for f in tools/fuzz-corpus/*.bin tools/fuzz-corpus/*.txt; do ...; done` (superseded after moving seeds under `tools/fuzz-corpus/seeds/`)
  - `moon info && moon fmt && printf '\377\377' | moon run --target native cmd/fuzz-native && tools/build-fuzz-native.sh _build/fuzz-native/telnet-fuzz-native && for f in tools/fuzz-corpus/seeds/*; do ...; done`
  - `moon info && moon fmt && moon test && printf '\377\377' | moon run --target native cmd/fuzz-native && tools/build-fuzz-native.sh _build/fuzz-native/telnet-fuzz-native && for f in tools/fuzz-corpus/seeds/*; do _build/fuzz-native/telnet-fuzz-native < "$f" >/dev/null; done && git diff --check` (tests passed; `git diff --check` flagged a generated `cmd/fuzz/pkg.generated.mbti` blank line at EOF, which was normalized)
  - `moon fmt --check && moon test && printf '\377\377' | moon run --target native cmd/fuzz-native && tools/build-fuzz-native.sh _build/fuzz-native/telnet-fuzz-native && for f in tools/fuzz-corpus/seeds/*; do _build/fuzz-native/telnet-fuzz-native < "$f" >/dev/null; done && git diff --check`: formatting check passed, 871 tests passed, native harness checksum `20`, standalone harness build passed, all corpus seeds passed, and whitespace check passed.
  - `git diff --cached --check` caught a CRLF/trailing-whitespace issue in the original plain seed; it was replaced with `plain.bin`, then `_build/fuzz-native/telnet-fuzz-native < tools/fuzz-corpus/seeds/plain.bin >/dev/null && git diff --cached --check` passed.

## Active work slices

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
