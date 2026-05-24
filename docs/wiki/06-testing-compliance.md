# 06 — Testing and Compliance

## Test layers

1. **Codec unit tests** — command constants, IAC escaping, chunk boundaries.
2. **Negotiation state tests** — RFC 1143 transitions and loop prevention.
3. **Option tests** — subnegotiation encoding/decoding for each supported option.
4. **Interop traces** — minimized byte transcripts from known clients/servers.
5. **Property/fuzz tests** — parser should never panic on arbitrary bytes.

## Fixture policy

- Prefer small handcrafted byte arrays derived from RFC examples.
- If importing external traces, record provenance and license in the fixture file.
- Keep expected parser events human-readable in test names or snapshots.

## Minimum completion criteria for each option

- Source RFC linked in `04-options-catalog.md`.
- Encoder and parser behavior documented.
- Positive and negative tests.
- Unknown/unsupported peer behavior documented.
- Compatibility notes for any intentional deviation from strict RFC behavior.
