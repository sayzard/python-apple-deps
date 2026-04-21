# Security Policy

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please report security issues by emailing the maintainers (see package.json or git log for contact) or opening a [GitHub Security Advisory](../../security/advisories/new).

Include:
- Description of the vulnerability
- Affected package and version
- Steps to reproduce

We will respond within 72 hours and aim to release a fix within 7 days of confirmation.

## Package Security Notes

| Package | Notes |
|---------|-------|
| OpenSSL | 3.4.x (4.0.0 excluded — breaking API changes). Update regularly. |
| liblzma | 5.6.0/5.6.1 excluded (CVE-2024-3094 backdoor). 5.8.3+ safe. |
| libheif | 1.21.2 excluded (CVE-2026-3950 use-after-free). Pinned to 1.20.2. |
| libxslt | End-of-maintenance Jul 2025. Monitor for alternative. |
