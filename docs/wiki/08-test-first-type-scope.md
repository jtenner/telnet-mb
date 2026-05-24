# 08 — Test-First Type Scope

This page defines the first public type surface for writing tests before implementing parser, encoder, or negotiation behavior. The types in `telnet.mbt` are intentionally data-only so fixtures can describe expected behavior without depending on production logic.

## Performance goals reflected in the types

- **Streaming first**: `ParserMode`, `ParserCheckpoint`, and `ParserState` model parsers that can pause at any byte boundary.
- **Copy avoidance**: `ByteSpan`, `BufferSlice`, and `BufferOwnership` let tests specify borrowed slices versus copied/scratch buffers.
- **Protocol fidelity**: commands, negotiation verbs, option sides, and RFC 1143 half-states are first-class types.
- **Bounded memory**: `ParserConfig` includes maximum data and subnegotiation sizes so tests can assert backpressure/error behavior.
- **Unknown-safe**: `KnownOption.Unknown`, raw `OptionCode`, and `OptionPayload.Raw` preserve unsupported protocol data.
- **Transport independence**: no TCP, terminal emulator, TLS provider, or async runtime types appear in the core API.

## Initial type groups

### Core protocol atoms

- `Command`
- `NegotiationVerb`
- `OptionSide`
- `OptionCode`
- `KnownOption`

Tests should use these to describe RFC 854 byte sequences and option-code mapping before command decoding is implemented.

### Byte views and events

- `ByteSpan`
- `DataEvent`
- `CommandEvent`
- `NegotiationEvent`
- `SubnegotiationEvent`
- `Event`
- `TelnetErrorKind`
- `TelnetError`

These types form the expected parser output. Golden tests should compare arrays of `Event` values against input byte chunks.

### Parser and encoder state

- `ParserMode`
- `CrPolicy`
- `DataCoalescing`
- `ParserConfig`
- `ParserCheckpoint`
- `ParserState`
- `EncodeItem`
- `EncodeErrorKind`
- `EncodeError`
- `BufferOwnership`
- `BufferSlice`

Parser tests should exercise every transition split across chunk boundaries. Encoder tests should distinguish raw data from TELNET-escaped data.

### Negotiation model

- `QueueBit`
- `HalfState`
- `OptionHalf`
- `OptionState`
- `PolicyDecision`
- `PolicyQuestion`
- `NegotiationAction`
- `NegotiationTransition`

These are the vocabulary for RFC 1143 Q-method tests. Each negotiation test should describe input state, incoming negotiation event, policy decision, resulting state, and emitted actions.

### Common option payloads

- `TerminalTypeMessage`
- `NawsSize`
- `EnvironmentVariableKind`
- `EnvironmentVariable`
- `EnvironmentMessage`
- `CharsetMessage`
- `LinemodeModeFlag`
- `LinemodeMode`
- `LinemodeForwardMask`
- `LinemodeMessage`
- `StartTlsMessage`
- `OptionPayload`

Option tests can now be written as payload-level fixtures before subnegotiation codecs are implemented.

## Work plan

### Step 1 — Type compilation gate

- Keep `telnet.mbt` data-only.
- Run `moon check`, `moon fmt`, and `moon info` whenever types change.
- Treat `pkg.generated.mbti` as the visible API contract.

### Step 2 — Test fixture helpers

Add test-only helpers in `_test.mbt` or `_wbtest.mbt` for:

- byte spans over fixture bytes,
- expected event arrays,
- expected negotiation transitions,
- compact names for common option codes.

These helpers may construct public structs directly while production constructors are still absent.

### Step 3 — Parser tests before parser code

Write failing tests for:

- plain data passthrough,
- `IAC IAC` data unescaping,
- all one-byte commands,
- `WILL/WON'T/DO/DON'T` triplets,
- subnegotiation with escaped IAC inside payload,
- incomplete sequence finalization errors,
- configured subnegotiation-size limit.

### Step 4 — Encoder tests before encoder code

Write failing tests for:

- escaping data byte `0xFF`,
- command encoding,
- negotiation encoding,
- subnegotiation payload escaping,
- output-buffer-too-small behavior for future zero-allocation APIs.

### Step 5 — Negotiation tests before negotiation code

Write failing tests for the RFC 1143 state machine:

- duplicate request handling,
- refusal handling,
- simultaneous enable/disable requests,
- queued opposite requests,
- unknown-option default refusal,
- policy-accepted custom option behavior.

### Step 6 — Implement only to satisfy tests

Once the tests describe the expected behavior, implement minimal production functions around these types. Keep allocation-sensitive APIs explicit about ownership and buffer requirements.
