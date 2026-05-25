# API Contract Skeleton

The public API skeleton lives in `api.mbt`. Function bodies intentionally use MoonBit `...` placeholders so the package exposes the intended signatures before production behavior is implemented.

## Parser

The parser is transport-independent and incremental.

- `Parser::default_config() -> ParserConfig`
- `Parser::new(ParserConfig) -> Parser`
- `Parser::default() -> Parser`
- `Parser::feed(Parser, Bytes) -> ParserFeedResult`
- `Parser::feed_span(Parser, ByteSpan) -> ParserFeedResult`
- `Parser::finish(Parser) -> ParserFinishResult`
- `Parser::checkpoint(Parser) -> ParserCheckpoint`
- `Parser::restore(ParserConfig, ParserCheckpoint) -> Parser`
- `Parser::reset(Parser) -> Parser`
- `Parser::with_config(Parser, ParserConfig) -> Parser`

Expected behavior:

- Consume arbitrary byte chunks.
- Preserve parser state across chunk boundaries.
- Emit TELNET events without owning a network transport.
- Report incomplete sequences on `finish`.
- Honor `ParserConfig` for CR policy, strictness, coalescing, and size limits.

## Encoder

The encoder writes canonical TELNET wire bytes.

- `Encoder::new() -> Encoder`
- `Encoder::canonical() -> Encoder`
- `Encoder::required_capacity(Encoder, EncodeItem) -> Int`
- `Encoder::encode_item(Encoder, EncodeItem, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_data(Encoder, ByteSpan, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_command(Encoder, Command, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_negotiation(Encoder, NegotiationEvent, Bytes) -> Result[EncodeResult, EncodeError]`
- `Encoder::encode_subnegotiation(Encoder, SubnegotiationEvent, Bytes) -> Result[EncodeResult, EncodeError]`

Expected behavior:

- Escape data byte `0xFF` as `IAC IAC`.
- Encode commands as `IAC <command>`.
- Encode negotiation as `IAC WILL/WON'T/DO/DON'T <option>`.
- Encode subnegotiation as `IAC SB <option> ... IAC SE` with payload IAC escaping.
- Fail atomically when output capacity is insufficient.

## Negotiator

The negotiator implements RFC 1143 Q-method state transitions.

- `Negotiator::new() -> Negotiator`
- `Negotiator::with_states(Array[OptionState]) -> Negotiator`
- `Negotiator::receive(Negotiator, NegotiationEvent, PolicyDecision) -> NegotiationTransition`
- `Negotiator::request(Negotiator, OptionCode, OptionSide, Bool) -> NegotiationTransition`
- `Negotiator::state_for(Negotiator, OptionCode) -> OptionState`
- `Negotiator::apply(Negotiator, NegotiationTransition) -> Negotiator`

Expected behavior:

- Track local and remote option halves independently.
- Avoid WILL/WON'T/DO/DON'T loops.
- Support queued opposite requests.
- Emit explicit actions for protocol responses and application notifications.

## Protocol mapping helpers

- `Command::from_byte(Byte) -> Command?`
- `Command::to_byte(Command) -> Byte`
- `NegotiationVerb::from_command(Command) -> NegotiationVerb?`
- `NegotiationVerb::to_command(NegotiationVerb) -> Command`
- `OptionCode::new(Byte) -> OptionCode`
- `OptionCode::to_byte(OptionCode) -> Byte`
- `KnownOption::from_code(OptionCode) -> KnownOption`
- `KnownOption::to_code(KnownOption) -> OptionCode`
- `ByteSpan::new(Bytes, Int, Int) -> ByteSpan`
- `ByteSpan::is_empty(ByteSpan) -> Bool`
- `ByteSpan::to_bytes(ByteSpan) -> Bytes`

## Option payload codecs

- `OptionPayload::decode(OptionCode, ByteSpan) -> Result[OptionPayload, TelnetError]`
- `OptionPayload::encode(OptionPayload, Bytes) -> Result[EncodeResult, EncodeError]`
- `OptionPayload::required_capacity(OptionPayload) -> Int`

Specific codec namespaces:

- `TerminalTypeMessage::decode/encode`
- `NawsSize::decode/encode`
- `EnvironmentMessage::decode/encode`
- `CharsetMessage::decode/encode`
- `LinemodeMessage::decode/encode`
- `StartTlsMessage::decode/encode`

## Behavioral TDD coverage

The public placeholder APIs are now exercised by two direct behavioral suites:

- `telnet_behavior_tdd_test.mbt` covers baseline parser, encoder, negotiator, mapping-helper, and option-codec behavior.
- `telnet_expanded_behavior_tdd_test.mbt` covers remaining blind spots: exhaustive representative parser split points, CR policy chunk boundaries, coalescing policies, strict/lenient invalid IAC recovery, malformed subnegotiation recovery, RFC 1143 queued-state negotiation, encoder atomicity/capacity formulas, raw-data bypass, malformed option codecs, and broader mapping-helper round trips.
- `telnet_missing_behavior_tdd_test.mbt` covers the last pre-implementation test families: parser checkpoint modes, `feed_span`, finish idempotence, absolute offsets, `bytes_consumed`, parser capacity boundaries, DM/Synch, encoder method equivalence and error metadata, negotiator non-mutation/option independence/full-state metadata, option encode/decode roundtrips, string edge cases, START_TLS transcript policy, and future BINARY/session behavior fixtures.
- `telnet_policy_blind_spots_tdd_test.mbt` locks down remaining policy/API choices: low-level session composition, explicit policy decisions, application-facing decoded option derivation, BINARY/NVT CR split, outgoing NVT canonicalization boundary, error metadata context, invalid `ByteSpan` and `ParserConfig` handling, parser-vs-codec responsibility, unsupported authentication/encryption scope, deeper NEW-ENVIRON/CHARSET/LINEMODE/NAWS/TTYPE behavior, negotiation storms, output queue planning, zero-copy span expectations, UTF-8 rejection, IANA mapping samples, and local-request transition shape.

## Session

The session is a transport-independent composition layer over `Parser`, `Encoder`,
`Negotiator`, and option codecs. It owns TELNET protocol state, but never owns a
socket, async runtime, terminal emulator, or TLS implementation.

### Get started

Use `Session` at the boundary between transport bytes and application TELNET
events. The struct carries the current parser mode, encoder, negotiation state,
policy, START_TLS state, and derived option metadata such as the latest NAWS
window size. The public methods return an updated session value instead of
mutating one in place; callers must keep that returned value for the next read or
write.

Minimal receive loop shape:

```moonbit nocheck
let mut session = @telnet.Session::default()
let out = Bytes::new(8192)
let input = read_from_transport_somehow()

match session.receive(input, out) {
  Ok(result) => {
    session = result.session
    write_to_transport(out, 0, result.bytes_written)
    handle_session_events(result.events)
  }
  Err(error) => handle_session_error(error)
}
```

Operational notes:

- Start with `Session::default()` for the default server-oriented policy, or use
  `Session::new(config)` when you need custom parser limits, text policies,
  decoded-payload behavior, or option support rules.
- `SessionPolicy` is the support declaration. Accepted incoming requests are
  answered automatically; built-in proactive support such as remote NAWS may be
  initiated by the first `receive` call.
- The output buffer is caller-owned. After `receive`, `send_data`,
  `request_option`, or `send_payload`, write exactly the reported
  `bytes_written` prefix to the transport.
- Save `SessionReceiveResult.session` or `SessionSendResult.session`; otherwise
  split-IAC parser state, negotiation transitions, TLS state, and tracked NAWS
  size will be lost.
- Inspect `SessionEvent` values for data, commands, negotiation notifications,
  decoded option payloads, START_TLS boundaries, and errors.
- Use `send_data` for application output, `request_option` for explicit WILL/DO
  requests, `send_payload` for subnegotiations, `get_window_size` for NAWS, and
  `mark_tls_active` after the adapter upgrades the underlying transport.

- `Session::default_config() -> SessionConfig`
- `Session::new(SessionConfig) -> Session`
- `Session::default() -> Session`
- `Session::receive(Session, Bytes, Bytes) -> Result[SessionReceiveResult, SessionError]`
- `Session::send_data(Session, ByteSpan, Bytes) -> Result[SessionSendResult, SessionError]`
- `Session::request_option(Session, OptionCode, OptionSide, Bool, Bytes) -> Result[SessionSendResult, SessionError]`
- `Session::send_payload(Session, OptionPayload, Bytes) -> Result[SessionSendResult, SessionError]`
- `Session::state_for(Session, OptionCode) -> OptionState`
- `Session::local_option_enabled(Session, OptionCode) -> Bool`
- `Session::remote_option_enabled(Session, OptionCode) -> Bool`
- `Session::incoming_binary(Session) -> Bool`
- `Session::outgoing_binary(Session) -> Bool`
- `Session::get_window_size(Session) -> WindowSize?`
- `Session::mark_tls_active(Session) -> Session`

Expected behavior:

- Internally force parser CR handling to `Preserve`; BINARY-aware text semantics
  belong at the session layer because negotiation may change mid-stream.
- Convert negotiation events through `SessionPolicy`, apply RFC 1143 transitions,
  encode generated replies into caller-provided output, and emit transparent
  `SessionEvent` state changes.
- Preserve streamability across arbitrary chunk boundaries, including split IAC
  commands, split negotiations, and split subnegotiations.
- Decode known subnegotiation payloads when configured, while preserving raw SB
  events for logging and unsupported options.
- Treat `SessionPolicy` accept rules as the session's built-in option support:
  accepted incoming requests are answered automatically, and built-in proactive
  support such as remote NAWS is negotiated opaquely on the first receive call.
- Track the latest decoded NAWS payload as `WindowSize::{ width, height }`,
  exposed by `Session::get_window_size()`, only after remote NAWS is negotiated.
- When local `ECHO` is negotiated, support server-side echo by escaping and
  writing received data bytes back into the caller-provided output buffer.
- Treat START_TLS `FOLLOWS` as a boundary event (`TransportUpgradeRequired`) for
  the application to upgrade its transport externally.
- Fail atomically with `SessionErrorKind::OutputBufferTooSmall` if generated
  output does not fit.

`telnet_session_tdd_test.mbt` records the executable contract for this API.

## Implementation status

The parser, encoder, negotiator, option-codec, and session APIs described above
are implemented and covered by behavioral tests. `telnet_session_tdd_test.mbt`
records the session contract, including streamability, policy-driven negotiation,
opaque remote-NAWS startup negotiation, server-side local ECHO, START_TLS
handoff events, and atomic output-buffer failure.
