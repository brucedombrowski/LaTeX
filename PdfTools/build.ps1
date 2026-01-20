# PDF Merge Tool - Windows PowerShell
# Merges multiple PDFs using LaTeX pdfpages package
#
# USAGE:
#   1. Copy this script to a folder with your PDFs
#   2. Right-click and select "Run with PowerShell"
#   3. Follow the prompts to select merge order

$ErrorActionPreference = "Stop"

# Configuration
$OutputPdf = "merged.pdf"
$TempTex = "merge_temp.tex"

# Cleanup function
function Cleanup {
    Remove-Item "merge_temp.*" -ErrorAction SilentlyContinue
}

# Register cleanup on exit
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Cleanup }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "PDF Merge Tool" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if pdflatex is installed
if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    Write-Host "Error: pdflatex not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install MiKTeX from: https://miktex.org/download" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Find PDF files in current directory
$PdfFiles = Get-ChildItem -Path . -Filter "*.pdf" -File |
    Where-Object { $_.Name -ne $OutputPdf -and $_.Name -notlike "merge_temp*" } |
    Sort-Object Name

# Check if we found any PDFs
if ($PdfFiles.Count -eq 0) {
    Write-Host "No PDF files found in current directory." -ForegroundColor Red
    Write-Host ""
    Write-Host "Place PDF files in the same folder as this script and run again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

if ($PdfFiles.Count -lt 2) {
    Write-Host "Only one PDF found. Need at least 2 PDFs to merge." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Found: $($PdfFiles[0].Name)" -ForegroundColor White
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Display found PDFs
Write-Host "Found PDFs in current directory:" -ForegroundColor Green
Write-Host ""
for ($i = 0; $i -lt $PdfFiles.Count; $i++) {
    $num = $i + 1
    Write-Host "  [$num] $($PdfFiles[$i].Name)" -ForegroundColor White
}
Write-Host ""

# Prompt for order
Write-Host 'Enter the order to merge (e.g., "2 1" or "2,1"):' -ForegroundColor White
$orderInput = Read-Host ">"

# Parse the order input (handle spaces, commas, or both)
$orderInput = $orderInput -replace ',', ' '
$order = $orderInput -split '\s+' | Where-Object { $_ -ne '' }

# Validate order input
if ($order.Count -lt 2) {
    Write-Host "Error: Please specify at least 2 PDFs to merge." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Validate each number and build selected files list
$selectedFiles = @()
foreach ($numStr in $order) {
    # Check if it's a valid number
    $num = 0
    if (-not [int]::TryParse($numStr, [ref]$num)) {
        Write-Host "Error: '$numStr' is not a valid number." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Check if it's in range
    if ($num -lt 1 -or $num -gt $PdfFiles.Count) {
        Write-Host "Error: $num is out of range (1-$($PdfFiles.Count))." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Get the file (convert to 0-indexed)
    $idx = $num - 1
    $selectedFiles += $PdfFiles[$idx]
}

# Show what we're merging
Write-Host ""
Write-Host "Merging PDFs in order:" -ForegroundColor Yellow
for ($i = 0; $i -lt $selectedFiles.Count; $i++) {
    $num = $i + 1
    Write-Host "  $num. $($selectedFiles[$i].Name)" -ForegroundColor White
}
Write-Host ""

# Generate LaTeX file
Write-Host "Creating $OutputPdf..." -ForegroundColor Yellow

$texContent = @"
\documentclass{article}
\usepackage{pdfpages}
\begin{document}
"@

foreach ($file in $selectedFiles) {
    $texContent += "`n\includepdf[pages=-]{$($file.Name)}"
}

$texContent += "`n\end{document}"

# Write the tex file
Set-Content -Path $TempTex -Value $texContent -Encoding UTF8

# Run pdflatex
try {
    $result = & pdflatex -interaction=nonstopmode $TempTex 2>&1
    if ($LASTEXITCODE -eq 0) {
        # Rename output
        if (Test-Path "merge_temp.pdf") {
            Move-Item "merge_temp.pdf" $OutputPdf -Force
            Write-Host "Done! Output: $OutputPdf" -ForegroundColor Green
        } else {
            throw "Output PDF not created"
        }
    } else {
        throw "pdflatex failed"
    }
} catch {
    Write-Host "Error: PDF merge failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Check that all input PDFs are valid and readable." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Cleanup
    exit 1
}

# Cleanup temporary files
Cleanup

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
