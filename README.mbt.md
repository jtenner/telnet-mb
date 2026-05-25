# jtenner/telnet

Transport-independent TELNET protocol core for MoonBit.

This package parses and emits TELNET byte streams, models TELNET commands and
option negotiation, and provides codecs for common subnegotiation payloads. It is
intended to sit below your TCP/TLS/runtime code and above application policy.

## Status

The core parser, encoder, option mapper, option-payload codecs, negotiation
state APIs, and transport-independent `Session` composition layer are implemented
and covered by a broad behavioral test corpus. Transport I/O, TLS handoff,
credential handling, and terminal rendering remain application responsibilities.

## Features

- Incremental TELNET parser for arbitrary byte chunks.
- TELNET encoder for data, commands, negotiation triplets, and subnegotiations.
- Canonical IAC escaping for data and subnegotiation payloads.
- WILL/WON'T/DO/DON'T negotiation state with explicit transition actions.
- Transport-independent `Session` orchestration for parser, encoder,
  negotiator, policy, and option codecs.
- Policy-driven option support with automatic replies to peer requests and
  opaque startup negotiation for built-in supported options such as remote NAWS.
- RFC/IANA command and option mapping helpers.
- Option-payload codecs for:
  - BINARY policy boundary
  - ECHO and SUPPRESS-GO-AHEAD negotiation
  - TERMINAL-TYPE
  - NAWS
  - LINEMODE
  - NEW-ENVIRON
  - CHARSET
  - START_TLS as a transport-security boundary codec
- Lossless raw preservation for unknown/private option payloads.
- Deterministic fuzz/property tests, target-parity checks, and native scanner
  stress coverage.

## Non-goals

- No TCP or async runtime dependency in the core package.
- No built-in remote shell server.
- No automatic credential handling.
- No terminal emulator.
- No bundled TLS implementation; `START_TLS FOLLOWS` is surfaced as a session
  boundary event for an adapter to upgrade the transport.

## Get started with `Session`

Use `Session` when you want the library to manage TELNET protocol state while
your application owns the transport. A `Session` value contains the parser,
encoder, RFC 1143 negotiator, option policy, START_TLS state, and tracked option
metadata such as NAWS window size. Treat it as an immutable state value: every
receive or send helper returns the next `Session` that you keep for the next I/O
turn.

1. Build a `SessionConfig` or start from `Session::default()`.
2. Allocate an output buffer large enough for generated TELNET replies.
3. Call `session.receive(input, out)` for each inbound transport chunk.
4. Write `out[0:result.bytes_written]` to your socket/TLS stream.
5. Save `result.session` and handle `result.events`.

```moonbit nocheck
let mut session = @telnet.Session::default()
let out = Bytes::new(8192)
let input = Bytes::from_array([
  255.to_byte(), 251.to_byte(), 1.to_byte(), // IAC WILL ECHO
  72.to_byte(), 105.to_byte(),
])

match session.receive(input, out) {
  Ok(result) => {
    session = result.session
    // Write the first result.bytes_written bytes of out to your transport.
    // Then inspect result.events for Data, negotiation state, decoded payloads,
    // START_TLS boundaries, and option enable/disable notifications.
  }
  Err(error) => {
    // Grow the output buffer if error.kind is OutputBufferTooSmall, or report
    // malformed/policy errors according to your adapter's rules.
  }
}
```

`SessionPolicy` declares which options this endpoint supports. Accepted peer
requests are answered automatically. The default server policy also starts
remote NAWS negotiation on the first receive call; after the peer enables NAWS
and sends a valid NAWS payload, read the latest size with
`session.get_window_size()`. If local ECHO is negotiated, received data is
escaped and echoed into the output buffer for you. Use `send_data` for outbound
application bytes, `request_option` for explicit WILL/DO state changes, and
`send_payload` for subnegotiation payloads. `START_TLS FOLLOWS` is surfaced as a
`TransportUpgradeRequired` event; perform the actual TLS upgrade outside the
session and then call `session.mark_tls_active()`.

## Quick examples

### Parse a stream

```moonbit nocheck
let parser = @telnet.Parser::default()
let result = parser.feed(Bytes::from_array([
  72.to_byte(), 105.to_byte(), 255.to_byte(), 246.to_byte(),
]))
// Events: Data("Hi"), Command(AYT)
```

For streaming input, keep the returned parser and feed the next chunk:

```moonbit nocheck
let first = @telnet.Parser::default().feed(Bytes::from_array([
  255.to_byte(), 251.to_byte(),
]))
let second = first.parser.feed(Bytes::from_array([1.to_byte()]))
// Event: Negotiation(WILL, ECHO)
```

### Encode TELNET bytes

```moonbit nocheck
let out = Bytes::new(3)
let event = @telnet.NegotiationEvent::{
  verb: @telnet.NegotiationVerb::Will,
  option: @telnet.OptionCode::new(1.to_byte()), // ECHO
}
let item = @telnet.EncodeItem::Negotiation(event)
ignore(@telnet.Encoder::canonical().encode_item(item, out))
// out == IAC WILL ECHO: [255, 251, 1]
```

Canonical data encoding doubles IAC bytes:

```moonbit nocheck
let data = @telnet.ByteSpan::new(
  Bytes::from_array([65.to_byte(), 255.to_byte(), 66.to_byte()]),
  0,
  3,
)
let out = Bytes::new(4)
ignore(@telnet.Encoder::canonical().encode_item(
  @telnet.EncodeItem::EscapedData(data),
  out,
))
// out == [65, 255, 255, 66]
```

### Decode subnegotiation payloads

```moonbit nocheck
let payload = @telnet.ByteSpan::new(
  Bytes::from_array([0.to_byte(), 80.to_byte(), 0.to_byte(), 24.to_byte()]),
  0,
  4,
)
match @telnet.OptionPayload::decode(@telnet.OptionCode::new(31.to_byte()), payload) {
  Ok(@telnet.OptionPayload::Naws(size)) => {
    // size.columns == 80, size.rows == 24
  }
  _ => ()
}
```

### Drive option negotiation

```moonbit nocheck
let negotiator = @telnet.Negotiator::new()
let incoming = @telnet.NegotiationEvent::{
  verb: @telnet.NegotiationVerb::Will,
  option: @telnet.OptionCode::new(1.to_byte()), // ECHO
}
let transition = negotiator.receive(incoming, @telnet.PolicyDecision::Accept)
let updated = negotiator.apply(transition)
// Encode any NegotiationAction::Send replies and write them on your transport.
```

### Use a Session

`Session` composes parsing, negotiation, encoding, and option codecs without
owning a socket. Keep the returned session between reads, write any generated
bytes from the output buffer to your transport, and handle emitted events.

```moonbit nocheck
let session = @telnet.Session::new(@telnet.SessionConfig::{
  parser_config: @telnet.Parser::default_config(),
  policy: @telnet.SessionPolicy::default_server(),
  incoming_text_policy: @telnet.SessionTextPolicy::Preserve,
  outgoing_text_policy: @telnet.SessionTextPolicy::Preserve,
  decode_known_options: true,
  emit_raw_subnegotiation: true,
  require_enabled_for_subnegotiation: false,
  reject_malformed_known_payloads: false,
  max_outbound_bytes: 8192,
})
let out = Bytes::new(64)
let result = session.receive(Bytes::new(0), out)
// With default_server policy, the first receive opaquely starts remote NAWS
// negotiation by writing IAC DO NAWS into out.
```

For server-side ECHO, accept local ECHO in `SessionPolicy`. Once `Local ECHO` is
negotiated, incoming data is escaped and echoed into the output buffer. For NAWS,
accept remote NAWS in policy; the session negotiates it opaquely on first
receive, and `Session::get_window_size()` is updated after remote NAWS is enabled
and a valid NAWS payload is received.

## Main API areas

- `Parser`: incremental byte-stream parser with `feed`, `feed_span`, `finish`,
  checkpoints, restore/reset, and configurable CR/coalescing/strictness policy.
- `Encoder`: canonical and raw TELNET byte encoders with capacity reporting.
- `Negotiator`: local/remote option-half state and explicit transition actions.
- `Session`: streamable protocol-state composition with policy-driven option
  support, generated output bytes, server-side ECHO, START_TLS boundary events,
  and NAWS window-size tracking.
- `OptionPayload`: decode/encode helpers for supported subnegotiation payloads.
- `ByteSpan`: public byte-slice model used by parser events and encoders.
- Mapping helpers: `Command`, `NegotiationVerb`, `OptionCode`, and `KnownOption`.

## Policy boundaries

The parser reports protocol events; `Session` adds TELNET state and policy but
still does not own transport or application security decisions.

- `CrPolicy` controls NVT CR/LF/CR-NUL handling at parser construction time;
  `Session` internally preserves parser data bytes so BINARY-aware semantics can
  be applied at the session layer.
- `SessionPolicy` is the source of option support. Accepted incoming option
  requests are answered automatically; built-in proactive support such as remote
  NAWS is negotiated opaquely on the first `Session::receive` call.
- BINARY negotiation is visible through negotiation state; it does not silently
  mutate parser configuration.
- `START_TLS FOLLOWS` decodes as a payload and is surfaced as
  `TransportUpgradeRequired`; plaintext blocking and transport upgrade
  enforcement remain adapter responsibilities.
- Unknown or unsupported option payloads can be preserved as `OptionPayload::Raw`.

## Supported options

| Code | Name | Notes |
|---:|---|---|
| 0 | BINARY | Negotiation/policy boundary; core parser exposes bytes. |
| 1 | ECHO | Negotiation support. |
| 3 | SUPPRESS-GO-AHEAD | Negotiation support. |
| 24 | TERMINAL-TYPE | `SEND`/`IS` payload codec. |
| 25 | END-OF-RECORD | Command/option mapping support. |
| 31 | NAWS | Width/height payload codec. |
| 34 | LINEMODE | Mode, SLC, and forward-mask payload codec. |
| 39 | NEW-ENVIRON | `IS`/`SEND`/`INFO` variable payload codec. |
| 42 | CHARSET | Request/accept/reject and TTABLE payload codec. |
| 46 | START_TLS | Payload codec; transport security is external. |

The full option source of truth is
[`docs/wiki/04-options-catalog.md`](docs/wiki/04-options-catalog.md). IANA
registry characterization is tracked in the executable tests and
[`docs/wiki/09-verification-corpus.md`](docs/wiki/09-verification-corpus.md).

## Testing

Normal validation:

```sh
moon info
moon fmt
moon test
```

Target-parity validation:

```sh
moon test --target js
moon test --target native
```

Deterministic fuzz profile:

```sh
moon run cmd/fuzz -- ci
moon run --target wasm cmd/fuzz -- ci
moon run --target wasm-gc cmd/fuzz -- ci
```

Additional guards:

```sh
bash tools/check-test-tautologies.sh
git diff --check
```

At the time this README was updated, `moon coverage analyze` reported no
uncovered lines in the core `api.mbt`; remaining uncovered lines were in command
harnesses under `cmd/`.

## Benchmarks

A runnable benchmark package lives in [`cmd/bench`](cmd/bench). It supports
JavaScript timing via `performance.now()`, native timing via a small
monotonic-clock C stub, and WebAssembly timing through a tiny JavaScript host
runner:

```sh
moon run --target js cmd/bench
moon run --target native cmd/bench

moon build --target wasm cmd/bench
node tools/run-wasm-bench.mjs _build/wasm/debug/build/cmd/bench/bench.wasm

moon build --target wasm-gc cmd/bench
bun tools/run-wasm-bench.mjs _build/wasm-gc/debug/build/cmd/bench/bench.wasm
```

The runner reports elapsed milliseconds, operations/second, approximate MB/s for
byte-oriented workloads, and a checksum for each benchmark.

Before publishing performance numbers, collect repeated runs and average every
benchmark row:

```sh
node tools/collect-benchmarks.mjs --runs 5 \
  --markdown _build/bench/report.md \
  --out _build/bench/report.json
```

Use `--targets js-node,js-bun,native,wasm-node,wasm-bun,wasm-gc-bun` to select a
subset, `--no-build` to reuse existing artifacts, and `--strict` to fail instead
of skipping unavailable runtimes such as Bun.

Local benchmark baselines should be refreshed when performance-sensitive parser,
encoder, or negotiator code changes. This table is intentionally compact; keep
full command output in release notes or PR logs when a detailed comparison is
needed.

| Date | Machine / runtime | Target | Representative local results |
|---|---|---:|---|
| 2026-05-25 | AMD Ryzen 7 8845HS, Node v20.19.2 | js | `parser_plain_1m_8192_chunks`: 611 MB/s; `parser_iac_escaped_sparse`: 171 MB/s; `encoder_raw_1m_assume_capacity`: 327 MB/s; `e2e_interactive_shell`: 6,170 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | js | `parser_plain_1m_8192_chunks`: 1,645 MB/s; `parser_iac_escaped_sparse`: 428 MB/s; `encoder_raw_1m_assume_capacity`: 1,134 MB/s; `e2e_interactive_shell`: 9,083 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Moon native | native | `parser_plain_1m_8192_chunks`: 21,531 MB/s; `parser_iac_escaped_sparse`: 178 MB/s; `encoder_raw_1m_assume_capacity`: 441 MB/s; `e2e_interactive_shell`: 2,596 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Node v20.19.2 | wasm | `parser_plain_1m_8192_chunks`: 864 MB/s; `parser_iac_escaped_sparse`: 97 MB/s; `encoder_raw_1m_assume_capacity`: 713 MB/s; `e2e_interactive_shell`: 3,061 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | wasm | `parser_plain_1m_8192_chunks`: 1,658 MB/s; `parser_iac_escaped_sparse`: 193 MB/s; `encoder_raw_1m_assume_capacity`: 774 MB/s; `e2e_interactive_shell`: 4,280 ops/s. |
| 2026-05-25 | AMD Ryzen 7 8845HS, Bun 1.3.13 | wasm-gc | `parser_plain_1m_8192_chunks`: 2,030 MB/s; `parser_iac_escaped_sparse`: 675 MB/s; `encoder_raw_1m_assume_capacity`: 2,035 MB/s; `e2e_interactive_shell`: 10,711 ops/s. |

Note: this local Node v20.19.2 runtime could run the wasm build but could not
instantiate the wasm-gc build; the wasm-gc row above was measured with Bun
1.3.13.

## Documentation

Start with [`docs/wiki/README.md`](docs/wiki/README.md). Useful pages include:

- [`docs/wiki/00-sources.md`](docs/wiki/00-sources.md) — RFC/IANA source policy.
- [`docs/wiki/02-protocol-model.md`](docs/wiki/02-protocol-model.md) — parser
  event model and TELNET byte stream notes.
- [`docs/wiki/03-option-negotiation.md`](docs/wiki/03-option-negotiation.md) —
  negotiation model.
- [`docs/wiki/04-options-catalog.md`](docs/wiki/04-options-catalog.md) — option
  support matrix.
- [`docs/wiki/06-testing-compliance.md`](docs/wiki/06-testing-compliance.md) —
  test and fuzz strategy.
- [`docs/wiki/conformance-matrix.md`](docs/wiki/conformance-matrix.md) —
  requirement-to-test traceability.

Protocol claims should be backed by RFC Editor, IETF Datatracker, or IANA
registry links in the wiki.

## License

MIT. See [`LICENSE`](LICENSE).
