# 00 — Normative Sources

The library should implement TELNET from RFC/IANA sources, not from ad-hoc client behavior unless explicitly documented as compatibility mode.

## Core protocol

| Source | Status in this wiki | Implementation relevance |
|---|---:|---|
| [RFC 854 — Telnet Protocol Specification](https://www.rfc-editor.org/rfc/rfc854) | Primary | TELNET byte stream, NVT model, command byte values, CR/NUL and CR/LF rules, IAC escaping, option negotiation framing. |
| [RFC 855 — Telnet Option Specifications](https://www.rfc-editor.org/rfc/rfc855) | Primary | Standard structure and defaults expected for TELNET option specs. |
| [RFC 1143 — Q Method of Implementing TELNET Option Negotiation](https://www.rfc-editor.org/rfc/rfc1143) | Primary implementation method | Avoids WILL/WON'T/DO/DON'T negotiation loops; use as default negotiation state machine. |
| [IANA Telnet Options registry](https://www.iana.org/assignments/telnet-options/telnet-options.xhtml) | Registry | Canonical option code assignment table. |

## Common options to implement early

| Source | Option/code | Notes |
|---|---:|---|
| [RFC 856 — Binary Transmission](https://www.rfc-editor.org/rfc/rfc856) | BINARY / 0 | Enables 8-bit data path semantics. |
| [RFC 857 — Echo](https://www.rfc-editor.org/rfc/rfc857) | ECHO / 1 | Common login/password behavior. |
| [RFC 858 — Suppress Go Ahead](https://www.rfc-editor.org/rfc/rfc858) | SUPPRESS-GO-AHEAD / 3 | Common character-at-a-time mode companion to ECHO. |
| [RFC 885 — End of Record](https://www.rfc-editor.org/rfc/rfc885) | EOR / 25 | Record boundary marker. |
| [RFC 1073 — Negotiate About Window Size](https://www.rfc-editor.org/rfc/rfc1073) | NAWS / 31 | Client sends width/height in subnegotiation. |
| [RFC 1091 — Terminal-Type](https://www.rfc-editor.org/rfc/rfc1091) | TERMINAL-TYPE / 24 | Server requests terminal type; client replies with NVT ASCII terminal name. |
| [RFC 1184 — Linemode](https://www.rfc-editor.org/rfc/rfc1184) | LINEMODE / 34 | Local line editing and special line characters. |
| [RFC 1572 — Environment](https://www.rfc-editor.org/rfc/rfc1572) | NEW-ENVIRON / 39 | Environment variable exchange. |
| [RFC 2066 — CHARSET](https://www.rfc-editor.org/rfc/rfc2066) | CHARSET / 42 | Character set negotiation. |
| [RFC 2946 — Data Encryption / START_TLS](https://www.rfc-editor.org/rfc/rfc2946) | START_TLS / 46 | Optional encryption negotiation; likely feature-gated. |

## Source update policy

- Check RFC Editor errata before marking a feature complete.
- Check the IANA registry before adding or renaming option constants.
- Store exact RFC fixture examples as minimized byte arrays, not wholesale RFC excerpts.
- Record implementation-specific compatibility decisions in `04-options-catalog.md`.
