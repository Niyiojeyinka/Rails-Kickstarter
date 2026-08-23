# Security Policy

## Supported versions

Only the latest release of Kickstart receives security fixes. Since Kickstart
is a starter kit, you are strongly encouraged to track `main` (or the latest
tag) and to keep generated dependencies updated via `bundle update` and
`yarn upgrade` (CI runs `bundler-audit` and `bin/importmap audit` on every PR).

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report them privately:

1. Open a [security advisory](https://github.com/OWNER/REPO/security/advisories/new)
   (replace OWNER/REPO with this repository), or
2. Email the maintainers directly (address listed in the repository settings).

Include as much detail as you can: affected version, steps to reproduce,
impact, and any suggested mitigation. You'll receive a response within a few
days. We request a 90-day coordinated disclosure window.

## What to check

Kickstart ships with production defaults: `RAILS_MASTER_KEY`-encrypted
credentials, parameter filtering, loopback-bound observability endpoints with
basic auth (see docs/OBSERVABILITY.md), and `brakeman`/`bundler-audit` in CI.
If you find a gap in those defaults, that's exactly the kind of report we
want.
