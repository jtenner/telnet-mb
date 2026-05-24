# 03 — Option Negotiation

TELNET option negotiation uses `WILL`, `WON'T`, `DO`, and `DON'T` triplets from RFC 854. The implementation should use RFC 1143's Q method to avoid acknowledgment loops and race bugs.

## State model

Maintain two independent halves for each option:

- **Local half** — whether this endpoint is performing the option (`WILL/WON'T` side).
- **Remote half** — whether the peer is performing the option (`DO/DON'T` side).

Each half should track RFC 1143 states conceptually equivalent to:

- `No`
- `Yes`
- `WantNo` with queued opposite request flag
- `WantYes` with queued opposite request flag

## Policy boundary

The negotiation engine should not hard-code which options are acceptable. It should ask a policy object/callback:

- May local side enable option X?
- May remote side enable option X?
- Should we initiate enable/disable for option X?
- What option handler should receive subnegotiation for option X?

## Required tests

- Duplicate `DO` for already-enabled local option is acknowledged only as required and does not loop.
- Refusal (`DON'T`/`WON'T`) transitions pending enable request back to disabled.
- Simultaneous enable requests converge to enabled.
- Unknown options default to refusal unless policy explicitly accepts.
- Subnegotiation is ignored or rejected when the option is not enabled, according to documented policy.

## Source

- [RFC 854](https://www.rfc-editor.org/rfc/rfc854)
- [RFC 1143](https://www.rfc-editor.org/rfc/rfc1143)
