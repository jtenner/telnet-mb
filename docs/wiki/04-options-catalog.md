# 04 — Options Catalog

Status key: `Planned`, `Core`, `Common`, `Advanced`, `Deferred`.

| Code | Name | Source | Status | Implementation notes |
|---:|---|---|---|---|
| 0 | BINARY | [RFC 856](https://www.rfc-editor.org/rfc/rfc856) | Common | Affects data interpretation; do not transform bytes in core codec. |
| 1 | ECHO | [RFC 857](https://www.rfc-editor.org/rfc/rfc857) | Common | Important for login/password flows. |
| 3 | SUPPRESS-GO-AHEAD | [RFC 858](https://www.rfc-editor.org/rfc/rfc858) | Common | Usually negotiated with ECHO for character-at-a-time operation. |
| 24 | TERMINAL-TYPE | [RFC 1091](https://www.rfc-editor.org/rfc/rfc1091) | Common | Server sends SEND; client replies IS with terminal name. |
| 25 | END-OF-RECORD | [RFC 885](https://www.rfc-editor.org/rfc/rfc885) | Common | Expose EOR as event/marker. |
| 31 | NAWS | [RFC 1073](https://www.rfc-editor.org/rfc/rfc1073) | Common | Subnegotiation carries width and height as 16-bit network-order values. |
| 34 | LINEMODE | [RFC 1184](https://www.rfc-editor.org/rfc/rfc1184) | Advanced | Requires mode and special-line-character handling. |
| 39 | NEW-ENVIRON | [RFC 1572](https://www.rfc-editor.org/rfc/rfc1572) | Advanced | Parse variable kinds and escaping carefully. |
| 42 | CHARSET | [RFC 2066](https://www.rfc-editor.org/rfc/rfc2066) | Advanced | Negotiates text encoding; core still exposes bytes. |
| 46 | START_TLS | [RFC 2946](https://www.rfc-editor.org/rfc/rfc2946) | Deferred | Needs TLS adapter design and security review. |

The full registry is maintained by IANA: <https://www.iana.org/assignments/telnet-options/telnet-options.xhtml>.

## Unknown option behavior

Default policy: refuse unknown options with `WON'T` or `DON'T` as appropriate. Applications may override this to pass through custom option codes.
