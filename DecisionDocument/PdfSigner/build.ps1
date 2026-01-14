# Build script for PdfSigner

$ErrorActionPreference = "Stop"

Write-Host "Building PdfSigner..." -ForegroundColor Cyan

# Check for dotnet CLI
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "Error: .NET SDK not found." -ForegroundColor Red
    Write-Host "Download from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
}

# Build the project
Push-Location $PSScriptRoot
try {
    dotnet build -c Release

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Build successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Output: bin\Release\net6.0\PdfSigner.exe" -ForegroundColor White
        Write-Host ""
        Write-Host "Usage:" -ForegroundColor Cyan
        Write-Host "  .\bin\Release\net6.0\PdfSigner.exe --list          # List certificates"
        Write-Host "  .\bin\Release\net6.0\PdfSigner.exe input.pdf       # Sign a PDF"
    }
}
finally {
    Pop-Location
}
