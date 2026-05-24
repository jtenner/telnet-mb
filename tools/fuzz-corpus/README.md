# Native fuzz seed corpus

`seeds/` contains tiny TELNET wire inputs for optional coverage-guided fuzzing
with `cmd/fuzz-native`. The files are intentionally small so mutation engines
can quickly discover nearby command, negotiation, IAC escaping, and
subnegotiation states.
