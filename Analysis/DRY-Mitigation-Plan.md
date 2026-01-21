# DRY Assessment Mitigation Plan

**Plan ID:** PLAN-2026-001
**Related Assessment:** ASSESS-2026-001 (DRY-Assessment-2026-01-21.md)
**Date:** January 21, 2026
**Target Release:** v0.3

---

## Executive Summary

This plan addresses the DRY violations identified in ASSESS-2026-001. Implementation will reduce code duplication by approximately 390 lines (84% reduction) and establish consistent template patterns across all document types.

---

## Implementation Phases

### Phase 1: Decision Memorandum Template System

**Priority:** High
**Estimated Effort:** 30 minutes
**Impact:** 280 lines eliminated

**Current State:**
- 4 decision documents duplicate ~70 lines of identical preamble each
- Files: `dm_sf901_decision.tex`, `DM-2026-002_*.tex`, `DM-2026-003_*.tex`
- Only document variables and content differ between files

**Implementation:**

1. Create `Decisions/_template.tex` with shared preamble:
   - Document class and geometry
   - Package imports
   - Header/footer configuration
   - List formatting
   - Custom commands

2. Define required variables in template:
   ```latex
   %% Required: \dmNumber, \dmTitle, \dmDate, \dmAuthor
   %% Required: \dmBackground, \dmDecision, \dmRationale
   ```

3. Refactor existing decisions to thin wrappers:
   ```latex
   \newcommand{\dmNumber}{DM-2026-002}
   \newcommand{\dmTitle}{SF901 Font Decision}
   % ... other variables ...
   \input{_template.tex}
   ```

4. Update `.scripts/release.sh` to handle new structure

**Acceptance Criteria:**
- [ ] All decision documents compile successfully
- [ ] PDF output identical to before refactoring
- [ ] New decisions can be created by copying example wrapper

---

### Phase 2: Meeting Agenda Wrapper System

**Priority:** High
**Estimated Effort:** 20 minutes
**Impact:** 110 lines eliminated

**Current State:**
- `project_kickoff.tex` and `requirements_review.tex` are full documents
- Duplicate 100% of template preamble
- Inconsistent with SF901/attestation pattern

**Implementation:**

1. Create `MeetingAgenda/templates/meeting_agenda_base.tex`:
   - Move all preamble and structure from current template
   - Define required variables interface

2. Refactor `meeting_agenda.tex` to be thin wrapper example

3. Refactor examples to thin wrappers:
   ```latex
   \newcommand{\meetingTitle}{Project Kickoff Meeting}
   \newcommand{\meetingDate}{January 21, 2026}
   % ... agenda items ...
   \input{../templates/meeting_agenda_base.tex}
   ```

**Acceptance Criteria:**
- [ ] All meeting agenda documents compile successfully
- [ ] PDF output matches original formatting
- [ ] Pattern consistent with SF901 examples

---

### Phase 3: Shell Script Common Utilities

**Priority:** Medium
**Estimated Effort:** 45 minutes
**Impact:** 50 lines eliminated

**Current State:**
- Color definitions repeated in 5 scripts
- Directory detection pattern in 4 scripts
- Cleanup commands duplicated

**Implementation:**

1. Create `.scripts/lib/common.sh`:
   ```bash
   #!/bin/bash
   # Common utilities for LaTeX Toolkit scripts

   # Colors
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   BLUE='\033[0;34m'
   NC='\033[0m'

   # Get repository root
   get_repo_root() {
       local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
       dirname "$script_dir"
   }

   # Cleanup LaTeX auxiliary files
   cleanup_aux_files() {
       local dir="${1:-.}"
       rm -f "$dir"/*.aux "$dir"/*.log "$dir"/*.out "$dir"/*.toc \
             "$dir"/*.fdb_latexmk "$dir"/*.fls "$dir"/*.synctex.gz
   }

   # Determine compiler based on file content
   determine_compiler() {
       local tex_file="$1"
       if grep -q '\\usepackage{fontspec}' "$tex_file" 2>/dev/null || \
          grep -q 'SF901-template' "$tex_file" 2>/dev/null; then
           echo "xelatex"
       else
           echo "pdflatex"
       fi
   }
   ```

2. Update scripts to source common.sh:
   - `.scripts/build-tex.sh`
   - `.scripts/release.sh`
   - `.scripts/generate-attestation.sh`
   - `.scripts/merge-pdf.sh`
   - `.scripts/sign-pdf.sh`

**Acceptance Criteria:**
- [ ] All scripts function identically after refactoring
- [ ] Common utilities sourced correctly
- [ ] No duplicate code for colors/utilities

---

### Phase 4: Minor Improvements

**Priority:** Low
**Estimated Effort:** 15 minutes

#### 4A. Unify Color Naming
- Rename `attblue` to `headerblue` in attestation-template.tex
- Ensures consistent naming across templates

#### 4B. Extract Compiler Detection in release.sh
- Move duplicated logic to function
- Already addressed by Phase 3 common.sh

#### 4C. Document DRY Patterns
- Add section to AGENTS.md explaining template wrapper pattern
- Include examples of correct usage

---

## Implementation Schedule

| Phase | Task | Status | Completed |
|-------|------|--------|-----------|
| 1 | Decision Memo template system | Complete | 2026-01-21 |
| 2 | Meeting Agenda wrapper system | Complete | 2026-01-21 |
| 3 | Shell script common utilities | Complete | 2026-01-21 |
| 4A | Color naming unification | Complete | 2026-01-21 |
| 4B | Compiler detection function | Complete | 2026-01-21 |
| 4C | Document DRY patterns | Complete | 2026-01-21 |

---

## Verification

After implementation, run full verification:

```bash
# Build all documents
./.scripts/release.sh

# Verify all PDFs generated
ls -la .dist/decisions/*.pdf
ls -la .dist/meetings/*.pdf
ls -la .dist/attestations/*.pdf

# Run attestation generation
./.scripts/generate-attestation.sh

# Verify symlinks work
ls -la Documentation-Generation/DecisionDocument/sign.sh
```

---

## Release Artifacts

Upon completion, the following will be generated for v0.3:

1. **Updated Attestation** - `Attestations/software-attestation-YYYYMMDD.pdf`
2. **Release Tag** - v0.3 with changelog
3. **Updated AGENTS.md** - DRY pattern documentation

---

## Rollback Plan

If issues arise:
1. Git revert to pre-implementation commit
2. Tag as v0.2.1 if needed
3. Document issues in assessment

---

## Success Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Decision memo lines | ~200 each | ~30 each | 85% reduction |
| Meeting agenda example lines | ~85 each | ~25 each | 70% reduction |
| Script boilerplate lines | ~50 total | ~10 total | 80% reduction |
| DRY Assessment Score | 7/10 | 9/10 | Improvement |

---

*Plan created by Claude Code*
*LaTeX Toolkit v0.2*
