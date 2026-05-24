# Conformance Matrix

This matrix maps current source-of-truth requirements to fixture and behavioral TDD coverage. The core implementation is still intentionally placeholder-based, so behavioral tests that call public APIs are expected to fail until production code replaces `...` bodies.

| Requirement area | Source | Test files | Status |
|---|---|---|---|
| RFC 854 command bytes and IAC framing | RFC 854 | `telnet_test.mbt`, `telnet_generated_cases_test.mbt`, `telnet_matrix_generated_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Data, escaped IAC, command/data ordering | RFC 854 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Subnegotiation framing and escaped IAC in payloads | RFC 854/RFC 855 | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Incomplete parser states and parser recovery | RFC 854 + project policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Strict vs lenient command policy | Project policy | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| NVT CR/LF/CR-NUL policy | RFC 854 + project policy | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| BINARY directional behavior | RFC 856 | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt` | Fixture coverage |
| ECHO and SUPPRESS-GO-AHEAD negotiation | RFC 857/RFC 858 | `telnet_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| RFC 1143 Q-method receiving transitions | RFC 1143 | `telnet_test.mbt`, `telnet_matrix_generated_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| RFC 1143 local initiation transitions | RFC 1143 | `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Option side validity policy | RFC option docs + project policy | `telnet_scenarios_test.mbt` | Fixture coverage |
| TERMINAL-TYPE | RFC 1091 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| NAWS | RFC 1073 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| NEW-ENVIRON | RFC 1572 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| CHARSET | RFC 2066 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| LINEMODE | RFC 1184 | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| START_TLS state boundary | RFC 2946 + project security policy | `telnet_test.mbt`, `telnet_edge_cases_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Encoder canonicalization and sizing | RFC 854 + project performance policy | `telnet_test.mbt`, `telnet_comprehensive_spec_test.mbt`, `telnet_blind_spots_test.mbt`, `telnet_scenarios_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt` | Fixture + failing behavioral TDD |
| Hostile/stress inputs | Project security policy | `telnet_comprehensive_spec_test.mbt`, `telnet_scenarios_test.mbt` | Fixture coverage |
| Public API contracts | Project API policy | `telnet_blind_spots_test.mbt`, `telnet_behavior_tdd_test.mbt`, `telnet_expanded_behavior_tdd_test.mbt`, `telnet_missing_behavior_tdd_test.mbt`, `api.mbt`, `docs/wiki/api-contract.md` | Public skeleton exposed with placeholders; expanded behavioral tests intentionally fail until implemented |
| Parser state, spans, offsets, and consumption accounting | RFC 854 + project zero-copy policy | `telnet_missing_behavior_tdd_test.mbt` | Failing behavioral TDD |
| Encoder method equivalence and error metadata | RFC 854 + project API policy | `telnet_missing_behavior_tdd_test.mbt` | Failing behavioral TDD |
| Negotiator mutation boundaries and option independence | RFC 1143 + project API policy | `telnet_missing_behavior_tdd_test.mbt` | Failing behavioral TDD |
| Option codec roundtrips and string edge cases | RFC 1091/RFC 1073/RFC 1572/RFC 2066/RFC 1184/RFC 2946 | `telnet_missing_behavior_tdd_test.mbt` | Failing behavioral TDD |
| Future Session/BINARY/START_TLS transcript policy | RFC 856/RFC 2946 + project session policy | `telnet_missing_behavior_tdd_test.mbt`, `telnet_policy_blind_spots_tdd_test.mbt`, `docs/wiki/api-contract.md` | Failing behavioral TDD + documented TODO |
| Invalid bounds/config hardening | Project API/security policy | `telnet_policy_blind_spots_tdd_test.mbt` | Failing behavioral TDD |
| Parser-vs-codec responsibility boundaries | Project architecture policy | `telnet_policy_blind_spots_tdd_test.mbt` | Failing behavioral TDD |
| Unsupported AUTH/ENCRYPT and private option scope | RFC option docs + project scope policy | `telnet_policy_blind_spots_tdd_test.mbt` | Failing behavioral TDD |
| Output queue planning and zero-copy expectations | Project performance policy | `telnet_policy_blind_spots_tdd_test.mbt` | Failing behavioral TDD |

## Remaining status labels

- **Fixture coverage**: Expected data and policy are represented, but production APIs are not called yet.
- **Contract fixtures only**: Future API names and behavior are described as strings or data, not real symbols.
- **Behavioral coverage**: Future state where tests call implementation functions directly.

Before release, all major rows should move from fixture coverage to behavioral coverage.
