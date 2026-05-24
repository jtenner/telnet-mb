#!/usr/bin/env bash
set -euo pipefail

# Validate the optional native TELNET fuzz harness without adding work to the
# default `moon test` path. The script always performs a quick non-instrumented
# stdin smoke run. If AFL++ is installed, it also builds an instrumented binary
# and runs a short stdin-mode AFL++ session against the checked-in seed corpus.
#
# Environment overrides:
#   FUZZ_NATIVE_BIN       non-instrumented output path
#   FUZZ_SEED_DIR         seed corpus directory
#   AFL_FUZZ             afl-fuzz binary name/path
#   AFL_CC               AFL++ compiler wrapper name/path
#   AFL_NATIVE_BIN       instrumented output path
#   AFL_SMOKE_SECONDS    AFL++ -V bounded run duration in seconds
#   AFL_OUT              AFL++ findings directory
#   REQUIRE_AFL=1        fail instead of skipping when AFL++ is unavailable

non_instrumented_bin=${FUZZ_NATIVE_BIN:-_build/fuzz-native/telnet-fuzz-native}
afl_fuzz=${AFL_FUZZ:-afl-fuzz}
afl_cc=${AFL_CC:-afl-clang-fast}
afl_seconds=${AFL_SMOKE_SECONDS:-5}
afl_out=${AFL_OUT:-_build/fuzz-findings/native-smoke}
afl_bin=${AFL_NATIVE_BIN:-_build/fuzz-native/telnet-fuzz-native-afl}
seed_dir=${FUZZ_SEED_DIR:-tools/fuzz-corpus/seeds}

printf '==> Building native fuzz harness with default compiler\n'
tools/build-fuzz-native.sh "$non_instrumented_bin"

printf '==> Running native stdin smoke probe\n'
printf '\377\377' | "$non_instrumented_bin"

if ! command -v "$afl_fuzz" >/dev/null 2>&1; then
  printf '==> Skipping AFL++ smoke: %s not found\n' "$afl_fuzz" >&2
  printf '    Install AFL++ and rerun, or set AFL_FUZZ=/path/to/afl-fuzz.\n' >&2
  if [[ "${REQUIRE_AFL:-0}" == "1" ]]; then
    exit 2
  fi
  exit 0
fi

if ! command -v "$afl_cc" >/dev/null 2>&1; then
  printf '==> Skipping AFL++ smoke: %s not found\n' "$afl_cc" >&2
  printf '    Install AFL++ compiler wrappers or set AFL_CC=/path/to/afl-clang-fast.\n' >&2
  if [[ "${REQUIRE_AFL:-0}" == "1" ]]; then
    exit 2
  fi
  exit 0
fi

if [[ ! -d "$seed_dir" ]]; then
  printf 'missing fuzz seed directory: %s\n' "$seed_dir" >&2
  exit 1
fi

printf '==> Building native fuzz harness with AFL++ compiler: %s\n' "$afl_cc"
CC="$afl_cc" tools/build-fuzz-native.sh "$afl_bin"

rm -rf "$afl_out"
mkdir -p "$afl_out"

printf '==> Running bounded AFL++ stdin smoke for %s seconds\n' "$afl_seconds"
AFL_NO_UI=${AFL_NO_UI:-1} \
AFL_SKIP_CPUFREQ=${AFL_SKIP_CPUFREQ:-1} \
"$afl_fuzz" -V "$afl_seconds" -i "$seed_dir" -o "$afl_out" -- "$afl_bin"

printf '==> AFL++ smoke complete; findings under %s\n' "$afl_out"
