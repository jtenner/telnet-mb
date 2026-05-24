#!/usr/bin/env bash
set -euo pipefail

out=${1:-_build/fuzz-native/telnet-fuzz-native}
cc=${CC:-${AFL_CC:-cc}}
rsp=_build/native/debug/build/cmd/fuzz-native/fuzz-native.rspfile
c_file=_build/native/debug/build/cmd/fuzz-native/fuzz-native.c

moon run --target native --build-only -v cmd/fuzz-native >/dev/null

mkdir -p "$(dirname "$out")"

common_flags=()
libs=()
while IFS= read -r line; do
  case "$line" in
    -I*|-L*|-D*|-g|-fPIC)
      common_flags+=("$line")
      ;;
    *.so)
      libs+=("$line")
      ;;
    -run|*.c|"")
      ;;
  esac
done < "$rsp"

stubs=()
for stub in \
  _build/native/debug/build/telnet_native.o \
  _build/native/debug/build/cmd/fuzz-native/fuzz_stdin.o; do
  if [[ -f "$stub" ]]; then
    stubs+=("$stub")
  fi
done

"$cc" \
  "${common_flags[@]}" \
  "$c_file" \
  "${libs[@]}" \
  "${stubs[@]}" \
  -Wl,-rpath,"$PWD/_build/native/debug/build" \
  -Wl,-rpath,"$PWD/_build/native/debug/build/cmd/fuzz-native" \
  -o "$out"

printf 'built %s with %s\n' "$out" "$cc"
