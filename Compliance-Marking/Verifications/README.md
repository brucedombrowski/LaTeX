# Verifications

Verification documents (VER-*) are co-located with the implementations they verify.

## VER Documents

| Document | Location | Verifies |
|----------|----------|----------|
| VER-2026-001 | `SendCUIEmail/Verifications/` | Cryptographic compliance (REQ-2026-001) |
| VER-2026-002 | `ORBIT-CEF-Status/docs/` | CUI handling compliance (REQ-2026-002/003) |

## Why VER Documents Live in Implementation Repos

Verification documents reference specific source files, line numbers, and code
snippets. Co-locating them with the implementation ensures:

1. Evidence references remain accurate as code evolves
2. Developers can review requirements alongside the code
3. CI/CD can validate that VER documents compile
4. Version control tracks VER updates with related code changes
