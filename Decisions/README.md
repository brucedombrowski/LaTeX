# Decision memoranda

## What belongs here, and what does not

**This repository is public.**

| | Where it lives |
|---|---|
| The shared template, `_template.tex` | **Here.** It is the reusable asset and the reason this directory exists. |
| Redacted examples, in `examples/` | **Here.** They showcase both capabilities: producing the artifact, and redacting it so the reasoning survives and the specifics do not. |
| Memoranda **addressed to real people, teams or offices** | **A private repository**, beside the work they concern. |

A memorandum written to a named recipient is correspondence, not a sample. It
does not become publishable by being well typeset.

## Where the addressed memoranda went

| Memo | Now in |
|---|---|
| DM-2026-007, 008, 009 | `ISS_Payload_CDH_Interface_PSI_Checklist/decisions/` |
| DM-2026-010 | `PCFPlan/decisions/` |
| DM-2026-012, 013 | `PSI-Training/decisions/` |

Each of those carries a vendored copy of `_template.tex` and `logo.png` so it
builds without this repository, and a `TEMPLATE_PROVENANCE.md` recording where
they came from. If the template changes here, re-copy it there.

## What remains

DM-2026-001, 002, 003 and 006 concern producing documents — SF 901 layout,
fonts, TikZ, requirements rendering. They are about the toolkit itself, and
their recipients are generic rather than named offices.

DM-2026-011 is unresolved: it is addressed to maintainer roles for repositories
that are themselves public. Decide whether it moves.

## Starting a real one

Copy a memo from `examples/`, replace the variables, and write it wherever the
work lives — not here.
