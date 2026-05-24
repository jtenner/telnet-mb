# 02 — Protocol Model

## Stream model

TELNET is a bidirectional byte stream over TCP with TELNET command bytes interspersed with application data. The core parser should therefore be incremental and resumable across arbitrary chunk boundaries.

## Core command constants

| Name | Decimal | Hex | Meaning |
|---|---:|---:|---|
| SE | 240 | 0xF0 | End subnegotiation. |
| NOP | 241 | 0xF1 | No operation. |
| DM | 242 | 0xF2 | Data mark. |
| BRK | 243 | 0xF3 | Break. |
| IP | 244 | 0xF4 | Interrupt process. |
| AO | 245 | 0xF5 | Abort output. |
| AYT | 246 | 0xF6 | Are you there. |
| EC | 247 | 0xF7 | Erase character. |
| EL | 248 | 0xF8 | Erase line. |
| GA | 249 | 0xF9 | Go ahead. |
| SB | 250 | 0xFA | Begin subnegotiation. |
| WILL | 251 | 0xFB | Sender offers/enables an option. |
| WONT | 252 | 0xFC | Sender refuses/disables an option. |
| DO | 253 | 0xFD | Sender asks peer to enable an option. |
| DONT | 254 | 0xFE | Sender asks peer to disable an option. |
| IAC | 255 | 0xFF | Interpret as command escape byte. |

Source: [RFC 854](https://www.rfc-editor.org/rfc/rfc854).

## Parser event model

Suggested public events:

- `Data(Bytes)` — ordinary application bytes after TELNET unescaping.
- `Command(Command)` — two-byte IAC command such as AYT or GA.
- `Negotiate(Direction, OptionCode)` — WILL/WONT/DO/DONT triplets.
- `Subnegotiation(OptionCode, Bytes)` — bytes between `IAC SB <option>` and `IAC SE`, with doubled IAC unescaped.
- `ProtocolError(Error)` — malformed sequence, unterminated subnegotiation when finalizing, or policy violation.

## Edge cases to test

- `IAC IAC` inside data produces one data byte `0xFF`.
- Command sequences split at every possible byte boundary.
- Subnegotiation payload containing `0xFF` uses doubled IAC in the wire representation.
- Malformed `IAC SB` without option byte is reported without losing parser state.
- Finalization reports incomplete `IAC`, negotiation triplet, or subnegotiation.
