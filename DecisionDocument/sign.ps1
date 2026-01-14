# Digital signature script for Decision Documents using smart card (PIV/CAC)
# Requires: OpenSC, JSignPDF, or similar PDF signing tool

param(
    [Parameter(Position=0)]
    [ValidateSet("sign", "verify", "list", "")]
    [string]$Action = "",

    [Parameter(Position=1)]
    [string]$PdfFile = ""
)

# Colors for output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }

Write-Host "=========================================="
Write-Host "PDF Digital Signature Script (Smart Card)"
Write-Host "=========================================="

# Global variables
$script:SignTool = ""
$script:PKCS11Lib = ""

function Test-Tools {
    $toolFound = $false

    # Check for pdfsig (from Poppler)
    if (Get-Command "pdfsig" -ErrorAction SilentlyContinue) {
        Write-Success "Found: pdfsig (Poppler)"
        $script:SignTool = "pdfsig"
        $toolFound = $true
    }

    # Check for JSignPDF
    $jsignPaths = @(
        "$env:ProgramFiles\JSignPdf\JSignPdf.jar",
        "$env:ProgramFiles(x86)\JSignPdf\JSignPdf.jar",
        "$env:LOCALAPPDATA\JSignPdf\JSignPdf.jar",
        "$env:USERPROFILE\JSignPdf\JSignPdf.jar"
    )

    foreach ($path in $jsignPaths) {
        if (Test-Path $path) {
            Write-Success "Found: JSignPDF at $path"
            $script:SignTool = "jsignpdf"
            $script:JSignJar = $path
            $toolFound = $true
            break
        }
    }

    # Check for OpenSC pkcs11-tool
    if (Get-Command "pkcs11-tool" -ErrorAction SilentlyContinue) {
        Write-Success "Found: pkcs11-tool (OpenSC)"
    }

    if (-not $toolFound) {
        Write-Error "Error: No PDF signing tool found."
        Write-Host ""
        Write-Host "Please install one of the following:"
        Write-Host "  JSignPDF:  Download from http://jsignpdf.sourceforge.net/"
        Write-Host "  Poppler:   Install via chocolatey: choco install poppler"
        Write-Host "  OpenSC:    Download from https://github.com/OpenSC/OpenSC/releases"
        Write-Host ""
        exit 1
    }
}

function Find-PKCS11Library {
    # Common PKCS#11 library locations on Windows
    $libs = @(
        "$env:SystemRoot\System32\opensc-pkcs11.dll",
        "$env:ProgramFiles\OpenSC Project\OpenSC\pkcs11\opensc-pkcs11.dll",
        "$env:ProgramFiles(x86)\OpenSC Project\OpenSC\pkcs11\opensc-pkcs11.dll",
        "$env:ProgramFiles\Yubico\Yubico PIV Tool\bin\libykcs11.dll",
        "$env:ProgramFiles(x86)\Yubico\Yubico PIV Tool\bin\libykcs11.dll"
    )

    foreach ($lib in $libs) {
        if (Test-Path $lib) {
            $script:PKCS11Lib = $lib
            Write-Success "Found PKCS#11 library: $lib"
            return $true
        }
    }

    Write-Warning "Warning: No PKCS#11 library found automatically."
    Write-Host "You may need to specify the path manually."
    return $false
}

function Get-SmartCardCertificates {
    Write-Host ""
    Write-Warning "Checking for smart card certificates..."

    if ($script:PKCS11Lib -and (Get-Command "pkcs11-tool" -ErrorAction SilentlyContinue)) {
        try {
            & pkcs11-tool --module $script:PKCS11Lib --list-objects --type cert
        }
        catch {
            Write-Warning "Could not list certificates. Is your smart card inserted?"
        }
    }
    else {
        Write-Warning "PKCS#11 library or pkcs11-tool not found. Cannot list certificates."
    }
}

function Sign-WithJSignPDF {
    param($InputPdf, $OutputPdf)

    if (-not $script:JSignJar) {
        Write-Error "JSignPDF jar not found."
        return $false
    }

    Write-Host ""
    Write-Warning "Signing with JSignPDF..."
    Write-Host "Please enter your smart card PIN when prompted."
    Write-Host ""

    $outDir = Split-Path -Parent $OutputPdf
    if (-not $outDir) { $outDir = "." }

    $javaArgs = @(
        "-jar", $script:JSignJar,
        "--keystore-type", "PKCS11",
        "--keystore-file", $script:PKCS11Lib,
        "--out-directory", $outDir,
        "--out-suffix", "_signed",
        $InputPdf
    )

    & java $javaArgs
    return $LASTEXITCODE -eq 0
}

function Sign-WithPdfSig {
    param($InputPdf, $OutputPdf)

    Write-Host ""
    Write-Warning "Signing with pdfsig..."
    Write-Host "Please enter your smart card PIN when prompted."
    Write-Host ""

    # Note: pdfsig requires NSS database setup for smart card signing
    # This is a simplified example - actual usage may require additional configuration
    & pdfsig -sign $InputPdf $OutputPdf
    return $LASTEXITCODE -eq 0
}

function Sign-Pdf {
    param($InputPdf)

    if (-not (Test-Path $InputPdf)) {
        Write-Error "Error: File not found: $InputPdf"
        exit 1
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPdf)
    $directory = Split-Path -Parent $InputPdf
    if (-not $directory) { $directory = "." }
    $outputPdf = Join-Path $directory "${baseName}_signed.pdf"

    Write-Host ""
    Write-Host "Input:  $InputPdf"
    Write-Host "Output: $outputPdf"

    $success = $false
    switch ($script:SignTool) {
        "jsignpdf" { $success = Sign-WithJSignPDF $InputPdf $outputPdf }
        "pdfsig" { $success = Sign-WithPdfSig $InputPdf $outputPdf }
        default {
            Write-Error "No signing tool configured."
            exit 1
        }
    }

    if ($success -and (Test-Path $outputPdf)) {
        Write-Host ""
        Write-Success "Successfully signed: $outputPdf"
    }
}

function Verify-Pdf {
    param($PdfFile)

    if (-not (Test-Path $PdfFile)) {
        Write-Error "Error: File not found: $PdfFile"
        exit 1
    }

    Write-Host ""
    Write-Warning "Verifying signatures in: $PdfFile"

    if (Get-Command "pdfsig" -ErrorAction SilentlyContinue) {
        & pdfsig $PdfFile
    }
    else {
        Write-Warning "pdfsig not found. Install Poppler to verify signatures."
    }
}

function Show-Usage {
    Write-Host ""
    Write-Host "Usage: .\sign.ps1 <action> [pdf_file]"
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  sign <file.pdf>   - Sign a PDF with smart card"
    Write-Host "  verify <file.pdf> - Verify signatures in a PDF"
    Write-Host "  list              - List certificates on smart card"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\sign.ps1 sign decision_document.pdf"
    Write-Host "  .\sign.ps1 verify decision_document_signed.pdf"
    Write-Host "  .\sign.ps1 list"
}

# Main script
Test-Tools
Find-PKCS11Library

switch ($Action) {
    "sign" {
        if (-not $PdfFile) {
            Write-Host ""
            Write-Host "Available PDFs:"
            Get-ChildItem -Filter "*.pdf" -Name 2>$null | ForEach-Object { Write-Host "  $_" }
            Write-Host ""
            $PdfFile = Read-Host "Enter PDF filename to sign"
        }
        Sign-Pdf $PdfFile
    }
    "verify" {
        if (-not $PdfFile) {
            Write-Host ""
            $PdfFile = Read-Host "Enter PDF filename to verify"
        }
        Verify-Pdf $PdfFile
    }
    "list" {
        Get-SmartCardCertificates
    }
    default {
        Show-Usage
    }
}
