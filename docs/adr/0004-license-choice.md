# ADR 0004 — Apache-2.0 for the code

**Status:** Accepted (Phase 0)

## Context
Étude ships on the App Store *and* is published as an open-source teaching resource. The
license must permit App Store distribution and give downstream users patent safety.
Copyleft licenses (GPL) are incompatible with App Store distribution terms.

## Decision
License the source under **Apache-2.0**: permissive, App-Store-compatible, with an
explicit patent grant. The **name, icon, and branding are not** covered by the code
license — the README states they may not be used for derivative store submissions, which
is the practical protection against clone re-uploads.

## Consequences
- Contributors and forkers get clear, permissive terms plus patent protection.
- Corpus `.ly` files keep their own upstream licenses (see `Corpus/LICENSES.md`); notably
  the Vivaldi Winter typesetting is CC-BY-SA and needs attribution.
- The app credits screen lists Mutopia attributions.
