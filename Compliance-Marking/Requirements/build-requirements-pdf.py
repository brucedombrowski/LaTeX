#!/usr/bin/env python3
"""
Build requirements PDF from JSON source.
JSON is the single source of truth; LaTeX/PDF are generated outputs.

Supports both REQ-2026-001 (SendCUIEmail) and REQ-2026-002/003 (CUI directive)
schemas. New fields (source_document, applicability) are handled gracefully;
their absence is tolerated for backward compatibility.

Usage: python3 build-requirements-pdf.py [json_file]
       If no file specified, processes all REQ-*.json files in directory.
"""

import json
import subprocess
import os
import sys
import hashlib
import glob
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def load_json(json_file):
    with open(json_file, 'r') as f:
        return json.load(f)

def get_json_hash(json_file):
    """Calculate SHA-256 hash of JSON file for traceability."""
    with open(json_file, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]  # First 16 chars

def escape_latex(text):
    """Escape special LaTeX characters."""
    replacements = [
        ('&', r'\&'),
        ('%', r'\%'),
        ('$', r'\$'),
        ('#', r'\#'),
        ('_', r'\_'),
        ('{', r'\{'),
        ('}', r'\}'),
        ('~', r'\textasciitilde{}'),
        ('^', r'\textasciicircum{}'),
        ('\u2014', '---'),   # em-dash
        ('\u2013', '--'),    # en-dash
        ('\u2018', '`'),     # left single quote
        ('\u2019', "'"),     # right single quote
        ('\u201c', '``'),    # left double quote
        ('\u201d', "''"),    # right double quote
    ]
    for old, new in replacements:
        text = text.replace(old, new)
    return text

def format_standard_id(std_id):
    """Convert JSON standard ID to display format."""
    if std_id.startswith("32-CFR"):
        return "32 CFR Part " + std_id.split("-")[-1]
    elif std_id.startswith("FIPS"):
        return std_id.replace("-", " ")
    elif std_id.startswith("NIST-SP"):
        parts = std_id.split("-")
        return f"NIST SP {parts[2]}-{parts[3]}" + (f"-{parts[4]}" if len(parts) > 4 else "")
    elif std_id.startswith("EO-"):
        return "EO " + std_id.split("-", 1)[1]
    elif std_id.startswith("NARA"):
        return std_id.replace("-", " ")
    return std_id

def format_date(date_str):
    """Convert 2026-01-22 to January 22, 2026."""
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    return dt.strftime("%B %d, %Y").replace(" 0", " ")

def get_project_name(data):
    """Extract project name from source_document or fall back to 'Project'."""
    src = data.get("source_document", {})
    if src.get("issuing_authority"):
        doc_id = src.get("id", "")
        return f"{src['issuing_authority']} {doc_id}".strip()
    return "Project"

def generate_source_document_block(data):
    """Generate LaTeX for the source_document provenance block, if present."""
    src = data.get("source_document")
    if not src:
        return ""

    tex = r"""
% ============================================================================
% SOURCE DOCUMENT PROVENANCE
% ============================================================================
\section{Source Document}

"""

    # Check if expired — add warning box
    status = src.get("status", "")
    if status.lower() == "expired":
        tex += r"""\begin{center}
\fcolorbox{red}{yellow!10}{%
\parbox{0.9\textwidth}{%
\centering\textbf{\textcolor{red}{EXPIRED DOCUMENT --- TEST DATA ONLY}}\\[4pt]
This requirements document is derived from an \textbf{expired} directive.
It is used for framework demonstration purposes only.
For production compliance, reference the successor document.
}}
\end{center}

\vspace{12pt}

"""
    elif status.lower() == "active":
        tex += r"""\begin{center}
\fcolorbox{green!60!black}{green!5}{%
\parbox{0.9\textwidth}{%
\centering\textbf{\textcolor{green!60!black}{CURRENT ACTIVE GOVERNING DOCUMENT}}\\[4pt]
This is the authoritative NASA procedural requirement for CUI management.
}}
\end{center}

\vspace{12pt}

"""

    # Document info table
    tex += r"\begin{tabular}{@{}ll@{}}" + "\n"
    if src.get("id"):
        tex += rf"\textbf{{Document ID:}} & {escape_latex(src['id'])} \\" + "\n"
    if src.get("title"):
        tex += rf"\textbf{{Title:}} & {escape_latex(src['title'])} \\" + "\n"
    if src.get("issuing_authority"):
        tex += rf"\textbf{{Issuing Authority:}} & {escape_latex(src['issuing_authority'])} \\" + "\n"
    if src.get("responsible_office"):
        tex += rf"\textbf{{Responsible Office:}} & {escape_latex(src['responsible_office'])} \\" + "\n"
    if src.get("effective_date"):
        tex += rf"\textbf{{Effective Date:}} & {format_date(src['effective_date'])} \\" + "\n"
    if src.get("expiration_date"):
        tex += rf"\textbf{{Expiration Date:}} & {format_date(src['expiration_date'])} \\" + "\n"
    tex += rf"\textbf{{Status:}} & \textbf{{{escape_latex(status)}}} \\" + "\n"
    if src.get("url"):
        tex += rf"\textbf{{URL:}} & \url{{{src['url']}}} \\" + "\n"
    tex += r"\end{tabular}" + "\n\n"

    # Successor/predecessor
    successor = src.get("successor")
    if successor:
        tex += r"\vspace{8pt}" + "\n"
        tex += r"\textbf{Successor Document:}" + "\n"
        tex += r"\begin{tabular}{@{}ll@{}}" + "\n"
        tex += rf"\textbf{{ID:}} & {escape_latex(successor.get('id', ''))} \\" + "\n"
        if successor.get("title"):
            tex += rf"\textbf{{Title:}} & {escape_latex(successor['title'])} \\" + "\n"
        if successor.get("effective_date"):
            tex += rf"\textbf{{Effective:}} & {format_date(successor['effective_date'])} \\" + "\n"
        if successor.get("url"):
            tex += rf"\textbf{{URL:}} & \url{{{successor['url']}}} \\" + "\n"
        tex += r"\end{tabular}" + "\n\n"

    predecessor = src.get("predecessor")
    if predecessor:
        tex += r"\vspace{8pt}" + "\n"
        tex += r"\textbf{Predecessor Document:}" + "\n"
        tex += r"\begin{tabular}{@{}ll@{}}" + "\n"
        tex += rf"\textbf{{ID:}} & {escape_latex(predecessor.get('id', ''))} \\" + "\n"
        if predecessor.get("status"):
            tex += rf"\textbf{{Status:}} & {escape_latex(predecessor['status'])} \\" + "\n"
        if predecessor.get("url"):
            tex += rf"\textbf{{URL:}} & \url{{{predecessor['url']}}} \\" + "\n"
        tex += r"\end{tabular}" + "\n\n"

    # Parent policy
    parent = src.get("parent_policy")
    if parent:
        tex += r"\vspace{8pt}" + "\n"
        tex += r"\textbf{Parent Policy:}" + "\n"
        tex += r"\begin{tabular}{@{}ll@{}}" + "\n"
        tex += rf"\textbf{{ID:}} & {escape_latex(parent.get('id', ''))} \\" + "\n"
        if parent.get("title"):
            tex += rf"\textbf{{Title:}} & {escape_latex(parent['title'])} \\" + "\n"
        if parent.get("url"):
            tex += rf"\textbf{{URL:}} & \url{{{parent['url']}}} \\" + "\n"
        tex += r"\end{tabular}" + "\n\n"

    # Federal authority
    fed = src.get("federal_authority", [])
    if fed:
        tex += r"\vspace{8pt}" + "\n"
        tex += r"\textbf{Federal Authority:} " + ", ".join(escape_latex(f) for f in fed) + "\n\n"

    # Note
    if src.get("note"):
        tex += r"\vspace{8pt}" + "\n"
        tex += rf"\textit{{{escape_latex(src['note'])}}}" + "\n\n"

    return tex

def get_applicability_badge(req):
    """Return LaTeX badge for applicability field."""
    app = req.get("applicability", "")
    if app == "technical":
        return r"\textcolor{blue}{\textbf{[T]}}"
    elif app == "organizational":
        return r"\textcolor{orange}{\textbf{[O]}}"
    elif app == "informational":
        return r"\textcolor{gray}{\textbf{[I]}}"
    return ""

def generate_latex(data, json_hash):
    doc = data["document"]
    standards = data["standards"]
    requirements = data["requirements"]
    summary = data["summary"]

    # Determine project name
    project_name = get_project_name(data)

    # Build standards lookup
    std_lookup = {s["id"]: s for s in standards}

    # Group requirements by category
    categories = {}
    for req in requirements:
        cat = req["category"]
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(req)

    # Format date
    formatted_date = format_date(doc["date"])

    # Check if we have applicability data
    has_applicability = any(r.get("applicability") for r in requirements)

    tex = rf"""\documentclass[11pt,letterpaper]{{article}}

% ============================================================================
% PACKAGES
% ============================================================================
\usepackage[margin=1in, top=1.5in, headheight=85pt]{{geometry}}
\usepackage{{fancyhdr}}
\usepackage{{lastpage}}
\usepackage{{enumitem}}
\usepackage{{xcolor}}
\usepackage{{hyperref}}
\usepackage{{tabularx}}
\usepackage{{booktabs}}
\usepackage{{longtable}}

% ============================================================================
% DOCUMENT VARIABLES (Generated from JSON)
% ============================================================================
\newcommand{{\UniqueID}}{{{doc["id"]}}}
\newcommand{{\DocumentDate}}{{{formatted_date}}}
\newcommand{{\AuthorName}}{{{escape_latex(project_name)}}}
\newcommand{{\DocumentTitle}}{{{escape_latex(doc["title"])}}}

% ============================================================================
% DOCUMENT CONFIGURATION
% ============================================================================
\hypersetup{{
    colorlinks=true,
    linkcolor=blue,
    urlcolor=blue,
    pdfborder={{0 0 0}},
    pdftitle={{{doc["id"]} {escape_latex(doc["title"])}}},
    pdfauthor={{{escape_latex(project_name)}}},
}}

\setlength{{\parindent}}{{0pt}}
\setlength{{\parskip}}{{6pt}}

% ============================================================================
% HEADER AND FOOTER
% ============================================================================
\pagestyle{{fancy}}
\fancyhf{{}}
\fancyhead[L]{{\textbf{{{escape_latex(project_name)}}}}}
\fancyhead[R]{{\parbox[b]{{3.5in}}{{\raggedleft\large\textbf{{Requirements Document}}}}}}
\renewcommand{{\headrulewidth}}{{0pt}}
\fancyfoot[L]{{\small \UniqueID}}
\fancyfoot[C]{{\small Page \thepage\ of \pageref{{LastPage}}}}
\fancyfoot[R]{{\small \DocumentDate}}
\renewcommand{{\footrulewidth}}{{0.4pt}}

% Define colors
\definecolor{{mandatory}}{{RGB}}{{220,53,69}}
\definecolor{{recommended}}{{RGB}}{{255,193,7}}
\definecolor{{optional}}{{RGB}}{{108,117,125}}

% ============================================================================
% BEGIN DOCUMENT
% ============================================================================
\begin{{document}}

\begin{{center}}
\Large\textbf{{\DocumentTitle}}\\[6pt]
\large\UniqueID\\[12pt]
\normalsize\DocumentDate
\end{{center}}

\vspace{{0.25in}}

% ============================================================================
% DOCUMENT INFO
% ============================================================================
\section*{{Document Information}}

\begin{{tabular}}{{@{{}}ll@{{}}}}
\textbf{{Document ID:}} & \UniqueID \\
\textbf{{Version:}} & {doc["version"]} \\
\textbf{{Status:}} & {doc["status"]} \\
\textbf{{Author:}} & \AuthorName \\
\textbf{{Date:}} & \DocumentDate \\
\textbf{{Source Hash:}} & \texttt{{{json_hash}}} \\
\end{{tabular}}

\vspace{{0.15in}}

\tableofcontents
\newpage

"""

    # Add source document block if present
    tex += generate_source_document_block(data)

    # Purpose section
    src = data.get("source_document", {})
    if src:
        src_id = escape_latex(src.get("id", "the source document"))
        src_status = src.get("status", "")
        tex += r"""% ============================================================================
% PURPOSE
% ============================================================================
\section{Purpose}

"""
        if src_status.lower() == "expired":
            tex += rf"""This document extracts and formalizes the normative requirements from {src_id} for use as \textbf{{test data}} in the systems-engineering V\&V framework. The source directive is expired; for production compliance, reference the successor document.

"""
        else:
            tex += rf"""This document extracts and formalizes the normative requirements from {src_id} to enable formal verification and validation (V\&V) against software implementations that handle Controlled Unclassified Information (CUI).

"""
    else:
        tex += r"""\section{Purpose}

This document defines the requirements to ensure compliance with applicable federal standards.

"""

    # Applicable Standards
    tex += r"""% ============================================================================
% APPLICABLE STANDARDS (Generated from JSON)
% ============================================================================
\section{Applicable Standards}

\begin{tabularx}{\textwidth}{lX}
\toprule
\textbf{Standard} & \textbf{Description} \\
\midrule
"""

    for std in standards:
        display_id = format_standard_id(std["id"])
        name = std["name"]
        url = std.get("url", "")
        if url:
            tex += rf"\href{{{url}}}{{{display_id}}} & {name} \\" + "\n"
        else:
            tex += rf"{display_id} & {name} \\" + "\n"

    tex += r"""\bottomrule
\end{tabularx}

"""

    # Requirements section
    tex += r"""% ============================================================================
% REQUIREMENTS (Generated from JSON)
% ============================================================================
\section{Requirements}

Requirements are categorized as:
\begin{itemize}[topsep=4pt, itemsep=2pt]
    \item \textcolor{mandatory}{\textbf{[M]}} -- Mandatory: Must be implemented (SHALL)
    \item \textcolor{recommended}{\textbf{[R]}} -- Recommended: Should be implemented where feasible (SHOULD)
    \item \textcolor{optional}{\textbf{[O]}} -- Optional: May be implemented (MAY)
\end{itemize}

"""

    if has_applicability:
        tex += r"""Applicability indicators:
\begin{itemize}[topsep=4pt, itemsep=2pt]
    \item \textcolor{blue}{\textbf{[T]}} -- Technical: Verifiable against a software implementation
    \item \textcolor{orange}{\textbf{[O]}} -- Organizational: Requires process or policy implementation
    \item \textcolor{gray}{\textbf{[I]}} -- Informational: Reference material, not directly testable
\end{itemize}

"""

    # Add requirements by category
    for cat_name in summary["categories"]:
        if cat_name not in categories:
            continue

        tex += rf"\subsection{{{cat_name}}}" + "\n\n"
        tex += r"""\begin{longtable}{@{}p{1.4cm}p{11.6cm}@{}}
\toprule
\textbf{ID} & \textbf{Requirement} \\
\midrule
\endfirsthead
\toprule
\textbf{ID} & \textbf{Requirement} \\
\midrule
\endhead

"""

        for req in categories[cat_name]:
            if req["priority"] == "Mandatory":
                priority_mark = r"\textcolor{mandatory}{\textbf{[M]}}"
            elif req["priority"] == "Recommended":
                priority_mark = r"\textcolor{recommended}{\textbf{[R]}}"
            else:
                priority_mark = r"\textcolor{optional}{\textbf{[O]}}"

            app_badge = get_applicability_badge(req) + " " if has_applicability and req.get("applicability") else ""
            desc = escape_latex(req["description"])
            tex += rf"{req['id']} & {priority_mark} {app_badge}{desc} \\[6pt]" + "\n\n"

        tex += r"""\bottomrule
\end{longtable}

"""

    # Verification methods
    tex += r"""% ============================================================================
% VERIFICATION
% ============================================================================
\section{Verification}

Each requirement SHALL be verified through one or more of the following methods:

\begin{tabularx}{\textwidth}{lX}
\toprule
\textbf{Method} & \textbf{Description} \\
\midrule
Inspection & Code review or document review to verify implementation matches requirement \\
Test & Automated or manual testing to verify correct behavior \\
Analysis & Review of design documentation, architecture, or parameters \\
\bottomrule
\end{tabularx}

\vspace{12pt}

Verification results are documented in the corresponding VER document.

"""

    # Traceability
    tex += r"""% ============================================================================
% TRACEABILITY (Generated from JSON)
% ============================================================================
\section{Requirements Traceability}

\begin{longtable}{@{}l l p{8cm}@{}}
\toprule
\textbf{Requirement} & \textbf{Standard} & \textbf{Section} \\
\midrule
\endfirsthead
\toprule
\textbf{Requirement} & \textbf{Standard} & \textbf{Section} \\
\midrule
\endhead

"""

    for req in requirements:
        req_id = req["id"]
        std_display = format_standard_id(req["standard"])
        trace = escape_latex(req.get("trace", ""))
        trace = trace.replace("§", r"\S")
        tex += rf"{req_id} & {std_display} & {trace} \\" + "\n"

    tex += r"""\bottomrule
\end{longtable}

"""

    # Summary
    tex += r"""% ============================================================================
% SUMMARY
% ============================================================================
\section{Summary}

"""
    tex += rf"""\begin{{tabular}}{{@{{}}ll@{{}}}}
\textbf{{Total Requirements:}} & {summary['total']} \\
\textbf{{Mandatory:}} & {summary['mandatory']} \\
\textbf{{Recommended:}} & {summary.get('recommended', 0)} \\
\textbf{{Optional:}} & {summary.get('optional', 0)} \\
\textbf{{Categories:}} & {len(summary['categories'])} \\
\end{{tabular}}

"""

    # Applicability breakdown if present
    app_breakdown = summary.get("applicability_breakdown")
    if app_breakdown:
        tex += r"""\vspace{12pt}
\textbf{Applicability Breakdown:}

\begin{tabular}{@{}ll@{}}
"""
        if app_breakdown.get("technical"):
            tex += rf"\textcolor{{blue}}{{\textbf{{Technical:}}}} & {app_breakdown['technical']} (verifiable against software) \\" + "\n"
        if app_breakdown.get("organizational"):
            tex += rf"\textcolor{{orange}}{{\textbf{{Organizational:}}}} & {app_breakdown['organizational']} (requires process/policy) \\" + "\n"
        if app_breakdown.get("informational"):
            tex += rf"\textcolor{{gray}}{{\textbf{{Informational:}}}} & {app_breakdown['informational']} (reference material) \\" + "\n"
        tex += r"""\end{tabular}

"""

    # Revision history
    tex += r"""% ============================================================================
% REVISION HISTORY
% ============================================================================
\section{Revision History}

\begin{tabularx}{\textwidth}{llX}
\toprule
\textbf{Version} & \textbf{Date} & \textbf{Description} \\
\midrule
"""

    tex += rf"{doc['version']} & {formatted_date} & Initial release \\" + "\n"

    tex += r"""\bottomrule
\end{tabularx}

\end{document}
"""

    return tex

def build_pdf(json_file):
    """Build PDF from a single JSON file."""
    data = load_json(json_file)
    version = data["document"]["version"]

    # Derive output filenames
    base_name = os.path.splitext(json_file)[0]
    versioned_base = f"{base_name}_v{version}"
    tex_file = versioned_base + ".tex"
    pdf_file = versioned_base + ".pdf"

    print(f"Building PDF from {os.path.basename(json_file)} (v{version})...")

    # Calculate hash for traceability
    json_hash = get_json_hash(json_file)
    print(f"  Source hash: {json_hash}")

    # Generate LaTeX
    print(f"  Generating: {os.path.basename(tex_file)}")
    tex = generate_latex(data, json_hash)

    with open(tex_file, 'w') as f:
        f.write(tex)

    # Compile PDF (twice for references / TOC)
    print("  Compiling PDF...")
    work_dir = os.path.dirname(os.path.abspath(json_file))
    os.chdir(work_dir)

    for i in range(2):
        result = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", os.path.basename(tex_file)],
            capture_output=True,
            text=True
        )
        if result.returncode != 0 and i == 1:
            print("  ERROR: pdflatex failed")
            print(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
            return 1

    # Clean auxiliary files
    for ext in [".aux", ".log", ".out", ".toc"]:
        aux_file = versioned_base + ext
        if os.path.exists(aux_file):
            os.remove(aux_file)

    print(f"  Created: {os.path.basename(pdf_file)}")
    return 0

def main():
    if len(sys.argv) > 1:
        json_files = [sys.argv[1]]
    else:
        json_files = sorted(glob.glob(os.path.join(SCRIPT_DIR, "REQ-*.json")))

    if not json_files:
        print("No JSON files found to process.")
        print("Usage: python3 build-requirements-pdf.py [json_file]")
        return 1

    errors = 0
    for json_file in json_files:
        result = build_pdf(json_file)
        if result != 0:
            errors += 1

    if errors:
        print(f"\n{errors} file(s) failed to build.")
        return 1

    print("\nDone.")
    return 0

if __name__ == "__main__":
    exit(main())
