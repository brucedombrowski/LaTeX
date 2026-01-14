# Build script for Decision Document LaTeX templates (Windows PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Decision Document Build Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if pdflatex is installed
if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    Write-Host "Error: pdflatex not found. Please install TeX Live or MiKTeX." -ForegroundColor Red
    exit 1
}

# Determine which document to build and check for --docx flag
$DOC = $null
$GENERATE_DOCX = $false

foreach ($arg in $args) {
    if ($arg -eq "--docx") {
        $GENERATE_DOCX = $true
    } elseif (-not $DOC) {
        $DOC = $arg
    }
}

if (-not $DOC) {
    Write-Host ""
    Write-Host "Which document would you like to build?"
    Write-Host "  1) decision_memo.tex (Decision Memorandum - brief)"
    Write-Host "  2) decision_document.tex (Comprehensive Decision Document)"
    Write-Host "  3) Both"
    Write-Host ""
    $choice = Read-Host "Enter choice [1-3]"
    switch ($choice) {
        "1" { $DOC = "decision_memo" }
        "2" { $DOC = "decision_document" }
        "3" { $DOC = "both" }
        default { Write-Host "Invalid choice" -ForegroundColor Red; exit 1 }
    }
}

# Required packages list (for reference)
$PACKAGES = "titlesec enumitem booktabs longtable lastpage datetime2 tabularx"

function Install-Packages {
    Write-Host "Attempting to install missing packages..." -ForegroundColor Yellow
    Write-Host "If using MiKTeX, packages should install automatically." -ForegroundColor Yellow
    Write-Host "If using TeX Live, run the following in an elevated prompt:" -ForegroundColor Yellow
    Write-Host "  tlmgr update --self" -ForegroundColor White
    Write-Host "  tlmgr install $PACKAGES" -ForegroundColor White
}

function Compile-Document {
    param([string]$docname)

    Write-Host ""
    Write-Host "Building ${docname}.tex..." -ForegroundColor Yellow

    # First pass
    $result = & pdflatex -interaction=nonstopmode "${docname}.tex" 2>&1
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    # Second pass
    Write-Host "Compiling (pass 2 of 3)..." -ForegroundColor Yellow
    & pdflatex -interaction=nonstopmode "${docname}.tex" | Out-Null

    # Third pass
    Write-Host "Compiling (pass 3 of 3)..." -ForegroundColor Yellow
    & pdflatex -interaction=nonstopmode "${docname}.tex" | Out-Null

    Write-Host "${docname}.pdf built successfully!" -ForegroundColor Green
    return $true
}

function Convert-ToDocx {
    param([string]$docname)

    if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
        Write-Host "pandoc not found. Install with: choco install pandoc" -ForegroundColor Yellow
        Write-Host "Skipping .docx generation." -ForegroundColor Yellow
        return $false
    }

    Write-Host "Converting ${docname}.tex to Word (with DRAFT watermark)..." -ForegroundColor Yellow

    # Use reference.docx for watermark if available
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $refDoc = Join-Path $scriptDir "reference.docx"
    $refArg = @()
    if (Test-Path $refDoc) {
        $refArg = @("--reference-doc=$refDoc")
    }

    try {
        & pandoc "${docname}.tex" -o "${docname}.docx" --from=latex --to=docx --standalone @refArg 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "${docname}.docx created successfully!" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Failed to convert ${docname}.tex to Word." -ForegroundColor Red
    }
    return $false
}

# Main build logic
$buildFailed = $false

if ($DOC -eq "both") {
    foreach ($doc in @("decision_memo", "decision_document")) {
        if (-not (Compile-Document $doc)) {
            $buildFailed = $true
            break
        }
    }
} else {
    if (-not (Compile-Document $DOC)) {
        $buildFailed = $true
    }
}

# Handle build failure
if ($buildFailed) {
    Write-Host "Compilation failed. Missing packages may be needed." -ForegroundColor Red
    Write-Host ""
    $reply = Read-Host "Would you like to see package installation instructions? (y/n)"
    if ($reply -match "^[Yy]$") {
        Install-Packages
    }
    exit 1
}

# Generate Word documents if --docx flag was passed
if ($GENERATE_DOCX) {
    Write-Host ""
    if ($DOC -eq "both") {
        foreach ($doc in @("decision_memo", "decision_document")) {
            Convert-ToDocx $doc
        }
    } else {
        Convert-ToDocx $DOC
    }
}

# Clean up auxiliary files by default
Write-Host ""
Write-Host "Cleaning up auxiliary files..." -ForegroundColor Yellow
$extensions = @("*.aux", "*.log", "*.out", "*.toc", "*.fdb_latexmk", "*.fls", "*.synctex.gz")
foreach ($ext in $extensions) {
    Remove-Item $ext -ErrorAction SilentlyContinue
}
Write-Host "Auxiliary files cleaned." -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
