# 07 — Maintenance

## Wiki stewardship

- The wiki is the source of truth for protocol scope and implementation decisions.
- Code comments may summarize behavior, but durable rationale belongs here.
- New options require updates to `00-sources.md`, `04-options-catalog.md`, and tests.

## Change workflow

1. Update wiki scope/design page.
2. Implement code.
3. Add or update tests.
4. Run `moon info && moon fmt && moon test`.
5. Note compatibility or security implications in the pull request/change summary.

## Release checklist

- `moon test` passes.
- Public API changes reflected in generated interface files after `moon info`.
- README support matrix matches `04-options-catalog.md`.
- RFC/IANA links checked.
- Security notes reviewed, especially for START_TLS or credential-sensitive flows.
