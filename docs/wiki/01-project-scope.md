# 01 — Project Scope

## Goal

Build a MoonBit TELNET library that can parse and emit TELNET streams, negotiate options safely, and expose protocol events without imposing a specific TCP runtime.

## Non-goals

- No built-in insecure remote shell server.
- No automatic credential handling.
- No terminal emulator implementation; terminal rendering belongs in another package.
- No network stack dependency in the core package. TCP adapters may be added separately.

## Release phases

### Phase 0 — Project and wiki bootstrap

- Generate MoonBit project with `moon new`.
- Add this wiki and source policy.
- Establish CI commands: `moon fmt`, `moon info`, `moon test`.

### Phase 1 — Core codec

- Constants for TELNET commands and well-known options.
- Streaming parser for data, escaped IAC data byte, commands, negotiation commands, and subnegotiation blocks.
- Encoder for the same event set.
- Unit tests for command framing and IAC doubling.

### Phase 2 — Negotiation engine

- Implement RFC 1143 Q-method state for local and remote option halves.
- Provide policy callbacks: accept, reject, request enable, request disable.
- Tests for loop prevention and simultaneous negotiation.

### Phase 3 — Common option handlers

- BINARY, ECHO, SUPPRESS-GO-AHEAD.
- TERMINAL-TYPE and NAWS subnegotiation.
- EOR marker support.

### Phase 4 — Advanced options

- LINEMODE.
- NEW-ENVIRON.
- CHARSET.
- START_TLS as an adapter boundary, not a bundled TLS implementation unless MoonBit ecosystem support is selected.

### Phase 5 — Interop and maintenance

- Golden traces from common TELNET clients/servers where licensing permits.
- Compatibility notes for legacy systems and MUD/BBS use cases.
- Versioned support matrix in `04-options-catalog.md`.
