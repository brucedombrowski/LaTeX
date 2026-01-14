# Digital signature script for Decision Documents
# Supports smart card (PIV/CAC) and software certificate (.p12/.pfx) signing
# Smart card signing uses Windows Certificate Store (preferred) or OpenSC as fallback
# Requires: OpenSSL for certificate creation (optional)

param(
    [Parameter(Position=0)]
    [ValidateSet("sign", "sign-p12", "verify", "list", "create-cert", "")]
    [string]$Action = "",

    [Parameter(Position=1)]
    [string]$Param1 = "",

    [Parameter(Position=2)]
    [string]$Param2 = ""
)

# Colors for output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Err { param($Message) Write-Host $Message -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "." }

Write-Host ""
Write-Host "=========================================="
Write-Host "PDF Digital Signature Script"
Write-Host "=========================================="

# Global variables
$script:SignTool = ""
$script:PKCS11Lib = ""
$script:JSignJar = ""
$script:HasOpenSSL = $false
$script:HasCertUtil = $false
$script:HasWindowsSmartCard = $false

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

    # Check for OpenSSL
    if (Get-Command "openssl" -ErrorAction SilentlyContinue) {
        Write-Success "Found: OpenSSL"
        $script:HasOpenSSL = $true
    }

    # Check for Windows certutil
    if (Get-Command "certutil" -ErrorAction SilentlyContinue) {
        Write-Success "Found: certutil (Windows)"
        $script:HasCertUtil = $true
    }

    if (-not $toolFound) {
        Write-Warn "Warning: No PDF signing tool found."
        Write-Host ""
        Write-Host "For signing, install one of the following:"
        Write-Host "  JSignPDF:  Download from http://jsignpdf.sourceforge.net/"
        Write-Host "  Poppler:   Install via chocolatey: choco install poppler"
        Write-Host ""
    }

    return $toolFound
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

    return $false
}

function Test-WindowsSmartCard {
    # Check if smart card certificates are available via Windows Certificate Store
    # This works without OpenSC if the smart card middleware is installed by Windows/enterprise
    try {
        # Look for any certificate with a private key - PIV cards may not have specific EKUs
        $smartCardCerts = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
            $_.HasPrivateKey
        }

        if ($smartCardCerts -and $smartCardCerts.Count -gt 0) {
            $script:HasWindowsSmartCard = $true
            Write-Success "Found Windows Certificate Store signing certificates"
            return $true
        }
    }
    catch {
        # Certificate store access failed
    }
    return $false
}

function Get-WindowsSigningCertificates {
    # Get certificates from Windows Certificate Store that can be used for signing
    # PIV cards typically have multiple certificates - we show all with private keys
    # and let the user choose which one to use for signing
    try {
        $certs = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
            $_.HasPrivateKey
        }
        return $certs
    }
    catch {
        return @()
    }
}

function Show-WindowsCertificates {
    Write-Host ""
    Write-Warn "Certificates in Windows Certificate Store (with private keys):"
    Write-Host ""

    $certs = Get-WindowsSigningCertificates
    if ($certs.Count -eq 0) {
        Write-Host "  No certificates with private keys found in Windows Certificate Store."
        Write-Host ""
        Write-Host "  If your smart card is inserted, certificates should appear here"
        Write-Host "  if Windows recognizes your card's middleware."
        return
    }

    $i = 1
    foreach ($cert in $certs) {
        $subject = $cert.Subject
        $issuer = $cert.Issuer -replace ".*CN=([^,]+).*", '$1'
        $expires = $cert.NotAfter.ToString("yyyy-MM-dd")
        # Get EKU (Extended Key Usage) to help identify certificate purpose
        $ekuList = @()
        if ($cert.EnhancedKeyUsageList) {
            $ekuList = $cert.EnhancedKeyUsageList | ForEach-Object { $_.FriendlyName }
        }
        $ekuStr = if ($ekuList.Count -gt 0) { $ekuList -join ", " } else { "General Purpose" }

        Write-Host "  $i) $subject"
        Write-Host "     Issuer: $issuer | Expires: $expires"
        Write-Host "     Usage: $ekuStr"
        Write-Host "     Thumbprint: $($cert.Thumbprint)"
        Write-Host ""
        $i++
    }
}

function Sign-WithWindowsCert {
    param($InputPdf, $OutputPdf, $CertThumbprint)

    Write-Host ""
    Write-Warn "Signing with Windows Certificate Store..."

    # Get the certificate
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }
    if (-not $cert) {
        Write-Err "Certificate not found with thumbprint: $CertThumbprint"
        return $false
    }

    Write-Host "Using certificate: $($cert.Subject)"

    # Check if JSignPDF is available (it can use Windows keystore via SunMSCAPI)
    if ($script:JSignJar) {
        Write-Host "Signing via JSignPDF with Windows keystore..."

        $outDir = Split-Path -Parent $OutputPdf
        if (-not $outDir) { $outDir = "." }

        # JSignPDF can use Windows-MY keystore
        $javaArgs = @(
            "-jar", $script:JSignJar,
            "--keystore-type", "WINDOWS-MY",
            "--key-alias", $cert.Subject,
            "--out-directory", $outDir,
            "--out-suffix", "_signed",
            $InputPdf
        )

        & java $javaArgs
        return $LASTEXITCODE -eq 0
    }

    # Fallback: Export cert to temp P12 and use existing P12 signing
    # This requires the private key to be exportable (may not work for smart cards)
    Write-Warn "JSignPDF not found. Attempting export-based signing..."
    Write-Host "Note: This may not work if the certificate's private key is non-exportable (smart cards)."

    try {
        $tempP12 = Join-Path $env:TEMP "temp_sign_$(Get-Random).p12"
        $tempPassword = [System.Guid]::NewGuid().ToString()

        # Try to export (will fail for non-exportable keys like smart cards)
        $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $tempPassword)
        [System.IO.File]::WriteAllBytes($tempP12, $certBytes)

        $result = Sign-WithP12 $InputPdf $OutputPdf $tempP12 $tempPassword

        # Clean up
        Remove-Item $tempP12 -Force -ErrorAction SilentlyContinue

        return $result
    }
    catch {
        Write-Err "Cannot export certificate private key."
        Write-Host "This is expected for smart card certificates."
        Write-Host ""
        Write-Host "To sign with smart cards, install JSignPDF:"
        Write-Host "  Download from http://jsignpdf.sourceforge.net/"
        return $false
    }
}

function Get-SmartCardCertificates {
    Write-Host ""
    Write-Warn "Checking for smart card certificates..."

    # First, show Windows Certificate Store certificates (preferred method)
    Show-WindowsCertificates

    # Also try OpenSC if available
    if ($script:PKCS11Lib -and (Get-Command "pkcs11-tool" -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Warn "OpenSC PKCS#11 certificates:"
        try {
            & pkcs11-tool --module $script:PKCS11Lib --list-objects --type cert 2>&1
        }
        catch {
            Write-Warn "Could not list OpenSC certificates. Is your smart card inserted?"
        }
    }
}

function Sign-WithJSignPDF {
    param($InputPdf, $OutputPdf, $P12File, $Password)

    if (-not $script:JSignJar) {
        Write-Err "JSignPDF jar not found."
        return $false
    }

    Write-Host ""
    Write-Warn "Signing with JSignPDF..."

    $outDir = Split-Path -Parent $OutputPdf
    if (-not $outDir) { $outDir = "." }

    $javaArgs = @("-jar", $script:JSignJar)

    if ($P12File) {
        # Software certificate signing
        $javaArgs += @(
            "--keystore-type", "PKCS12",
            "--keystore-file", $P12File,
            "--keystore-password", $Password
        )
    }
    else {
        # Smart card signing
        Write-Host "Please enter your smart card PIN when prompted."
        $javaArgs += @(
            "--keystore-type", "PKCS11",
            "--keystore-file", $script:PKCS11Lib
        )
    }

    $javaArgs += @(
        "--out-directory", $outDir,
        "--out-suffix", "_signed",
        $InputPdf
    )

    & java $javaArgs
    return $LASTEXITCODE -eq 0
}

function Sign-WithPdfSig {
    param($InputPdf, $OutputPdf, $NssDir, $CertNick)

    Write-Host ""
    Write-Warn "Signing with pdfsig..."

    if ($NssDir -and $CertNick) {
        # Software certificate via NSS
        & pdfsig -nssdir $NssDir -nick $CertNick -add-signature $InputPdf $OutputPdf
    }
    else {
        # Smart card signing
        Write-Host "Please enter your smart card PIN when prompted."
        & pdfsig -sign $InputPdf $OutputPdf
    }
    return $LASTEXITCODE -eq 0
}

function Sign-WithP12 {
    param($InputPdf, $OutputPdf, $P12File, $Password)

    Write-Host ""
    Write-Warn "Signing with software certificate..."

    # Check for required tools
    if (-not (Get-Command "certutil" -ErrorAction SilentlyContinue)) {
        Write-Err "Error: Windows certutil not found."
        return $false
    }

    if (-not (Get-Command "pdfsig" -ErrorAction SilentlyContinue)) {
        # Try JSignPDF instead
        if ($script:JSignJar) {
            return Sign-WithJSignPDF $InputPdf $OutputPdf $P12File $Password
        }
        Write-Err "Error: pdfsig not found and JSignPDF not available."
        Write-Host "Install Poppler: choco install poppler"
        return $false
    }

    # Create temporary NSS database
    $nssDir = Join-Path $env:TEMP "nss_$(Get-Random)"
    New-Item -ItemType Directory -Path $nssDir -Force | Out-Null

    Write-Host "Creating temporary NSS database..."

    # Initialize NSS database
    & certutil -N -d "sql:$nssDir" --empty-password 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to create NSS database."
        Remove-Item -Recurse -Force $nssDir -ErrorAction SilentlyContinue
        return $false
    }

    Write-Host "Importing certificate..."

    # Import the P12 certificate using pk12util if available, otherwise certutil
    if (Get-Command "pk12util" -ErrorAction SilentlyContinue) {
        & pk12util -i $P12File -d "sql:$nssDir" -W $Password 2>&1
    }
    else {
        # Use certutil for import (Windows version)
        & certutil -importpfx -p $Password -d "sql:$nssDir" $P12File 2>&1
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to import certificate. Check password."
        Remove-Item -Recurse -Force $nssDir -ErrorAction SilentlyContinue
        return $false
    }

    # List certificates to find the nickname
    Write-Host ""
    Write-Host "Available certificates in database:"
    & certutil -L -d "sql:$nssDir" 2>&1

    # Get the certificate nickname (look for user certs with "u,u,u" trust)
    $certOutput = & certutil -L -d "sql:$nssDir" 2>&1 | Select-String "u,u,u"
    if ($certOutput) {
        $certNick = ($certOutput.Line -replace '\s*u,u,u$', '').Trim()
    }
    else {
        # Try getting any cert
        $certOutput = & certutil -L -d "sql:$nssDir" 2>&1 | Where-Object { $_ -match '\S' -and $_ -notmatch '^Certificate' }
        if ($certOutput) {
            $certNick = ($certOutput[0] -replace '\s+\S+$', '').Trim()
        }
    }

    if (-not $certNick) {
        Write-Err "No certificate found in database."
        Remove-Item -Recurse -Force $nssDir -ErrorAction SilentlyContinue
        return $false
    }

    Write-Host ""
    Write-Host "Using certificate: $certNick"
    Write-Host "Signing PDF..."

    # Sign the PDF
    $result = Sign-WithPdfSig $InputPdf $OutputPdf "sql:$nssDir" $certNick

    # Clean up
    Remove-Item -Recurse -Force $nssDir -ErrorAction SilentlyContinue

    if ($result -and (Test-Path $OutputPdf)) {
        Write-Host ""
        Write-Success "PDF signed successfully!"
        Write-Host "Output: $OutputPdf"
        return $true
    }
    else {
        Write-Err "Signing failed."
        return $false
    }
}

function Sign-Pdf {
    param($InputPdf)

    if (-not (Test-Path $InputPdf)) {
        Write-Err "Error: File not found: $InputPdf"
        return $false
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
        "jsignpdf" { $success = Sign-WithJSignPDF $InputPdf $outputPdf $null $null }
        "pdfsig" { $success = Sign-WithPdfSig $InputPdf $outputPdf $null $null }
        default {
            Write-Err "No signing tool configured."
            return $false
        }
    }

    if ($success -and (Test-Path $outputPdf)) {
        Write-Host ""
        Write-Success "Successfully signed: $outputPdf"
    }
    return $success
}

function Verify-Pdf {
    param($PdfFile)

    if (-not (Test-Path $PdfFile)) {
        Write-Err "Error: File not found: $PdfFile"
        return
    }

    Write-Host ""
    Write-Warn "Verifying signatures in: $PdfFile"
    Write-Host ""

    if (Get-Command "pdfsig" -ErrorAction SilentlyContinue) {
        & pdfsig $PdfFile
    }
    else {
        Write-Warn "pdfsig not found. Install Poppler to verify signatures."
        Write-Host "  choco install poppler"
    }
}

function Create-TestCertificate {
    Write-Host ""
    Write-Warn "Creating self-signed test certificate..."
    Write-Host ""
    Write-Host "This creates a certificate for TESTING PURPOSES ONLY."
    Write-Host "Do not use for production or legal documents."
    Write-Host ""

    if (-not $script:HasOpenSSL) {
        Write-Err "Error: OpenSSL is required to create certificates."
        Write-Host ""
        Write-Host "Install OpenSSL:"
        Write-Host "  choco install openssl"
        Write-Host "  or download from: https://slproweb.com/products/Win32OpenSSL.html"
        return
    }

    # Get signer information
    $signerName = Read-Host "Enter signer name (e.g., John Smith)"
    if (-not $signerName) {
        Write-Err "Signer name is required."
        return
    }

    $orgName = Read-Host "Enter organization name (e.g., Example Corp) [optional]"
    $countryCode = Read-Host "Enter country code (e.g., US) [default: US]"
    if (-not $countryCode) { $countryCode = "US" }

    $password = Read-Host "Enter password for the certificate" -AsSecureString
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )

    if (-not $passwordPlain) {
        Write-Err "Password is required."
        return
    }

    # Create filename from signer name
    $fileName = ($signerName -replace '\s+', '_').ToLower()
    $keyFile = Join-Path $ScriptDir "${fileName}_key.pem"
    $certFile = Join-Path $ScriptDir "${fileName}_cert.pem"
    $p12File = Join-Path $ScriptDir "${fileName}.p12"

    Write-Host ""
    Write-Host "Generating RSA private key..."

    # Build subject string
    $subject = "/C=$countryCode"
    if ($orgName) { $subject += "/O=$orgName" }
    $subject += "/CN=$signerName"

    # Generate private key
    & openssl genrsa -out $keyFile 2048 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to generate private key."
        return
    }

    Write-Host "Creating X.509 certificate..."

    # Create certificate
    & openssl req -new -x509 -key $keyFile -out $certFile -days 365 -subj $subject 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to create certificate."
        return
    }

    Write-Host "Creating PKCS#12 bundle..."

    # Create P12 bundle
    & openssl pkcs12 -export -out $p12File -inkey $keyFile -in $certFile -passout "pass:$passwordPlain" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to create P12 bundle."
        return
    }

    Write-Host ""
    Write-Success "Certificate created successfully!"
    Write-Host ""
    Write-Host "Files created:"
    Write-Host "  Private key:  $keyFile"
    Write-Host "  Certificate:  $certFile"
    Write-Host "  P12 bundle:   $p12File"
    Write-Host ""
    Write-Host "To sign a PDF with this certificate:"
    Write-Host "  .\sign.ps1 sign-p12 $p12File <your_document.pdf>"
    Write-Host ""
    Write-Warn "IMPORTANT: Keep your private key secure!"
    Write-Host "The .p12 file contains both the private key and certificate."
}

function Show-Usage {
    Write-Host ""
    Write-Host "Usage: .\sign.ps1 <action> [options]"
    Write-Host ""
    Write-Host "Actions:"
    Write-Host "  sign <file.pdf>                    - Sign PDF with smart card (PIV/CAC)"
    Write-Host "  sign-p12 <cert.p12> <file.pdf>     - Sign PDF with software certificate"
    Write-Host "  verify <file.pdf>                  - Verify signatures in a PDF"
    Write-Host "  list                               - List certificates on smart card"
    Write-Host "  create-cert                        - Create a self-signed test certificate"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\sign.ps1 sign decision_document.pdf"
    Write-Host "  .\sign.ps1 sign-p12 test_signer.p12 decision_document.pdf"
    Write-Host "  .\sign.ps1 verify decision_document_signed.pdf"
    Write-Host "  .\sign.ps1 list"
    Write-Host "  .\sign.ps1 create-cert"
    Write-Host ""
    Write-Host "Run without arguments for interactive mode."
}

function Show-InteractiveMenu {
    Write-Host ""
    Write-Warn "What would you like to do?"
    Write-Host ""
    Write-Host "  1) Sign a PDF document"
    Write-Host "  2) Verify a signed PDF"
    Write-Host "  3) Create a test certificate"
    Write-Host "  4) List smart card certificates"
    Write-Host "  5) Show command-line usage"
    Write-Host "  6) Exit"
    Write-Host ""
    $choice = Read-Host "Enter choice [1-6]"

    switch ($choice) {
        "1" { Sign-Interactive }
        "2" { Verify-Interactive }
        "3" { Create-TestCertificate; Pause-Continue; Show-InteractiveMenu }
        "4" { Get-SmartCardCertificates; Pause-Continue; Show-InteractiveMenu }
        "5" { Show-Usage; Pause-Continue; Show-InteractiveMenu }
        "6" { Write-Host "Goodbye!"; exit 0 }
        default {
            Write-Err "Invalid choice. Please enter 1-6."
            Show-InteractiveMenu
        }
    }
}

function Pause-Continue {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Sign-Interactive {
    Write-Host ""
    Write-Warn "How would you like to sign?"
    Write-Host ""
    Write-Host "  1) Use a software certificate (.p12/.pfx file)"
    Write-Host "  2) Use a smart card (PIV/CAC)"
    Write-Host "  3) Back to main menu"
    Write-Host ""
    $signChoice = Read-Host "Enter choice [1-3]"

    switch ($signChoice) {
        "1" { Sign-WithSoftwareCertInteractive }
        "2" { Sign-WithSmartCardInteractive }
        "3" { Show-InteractiveMenu }
        default {
            Write-Err "Invalid choice."
            Sign-Interactive
        }
    }
}

function Sign-WithSoftwareCertInteractive {
    Write-Host ""

    # Check for existing .p12/.pfx files
    $p12Files = @(Get-ChildItem -Path $ScriptDir -Filter "*.p12" -ErrorAction SilentlyContinue)
    $p12Files += @(Get-ChildItem -Path $ScriptDir -Filter "*.pfx" -ErrorAction SilentlyContinue)

    if ($p12Files.Count -eq 0) {
        Write-Warn "No .p12 or .pfx certificate files found."
        Write-Host ""
        Write-Host "  1) Create a new test certificate"
        Write-Host "  2) Enter path to existing certificate file"
        Write-Host "  3) Back to main menu"
        Write-Host ""
        $certChoice = Read-Host "Enter choice [1-3]"

        switch ($certChoice) {
            "1" {
                Create-TestCertificate
                Pause-Continue
                Sign-WithSoftwareCertInteractive
                return
            }
            "2" {
                $p12File = Read-Host "Enter full path to .p12 or .pfx file"
            }
            "3" {
                Show-InteractiveMenu
                return
            }
            default {
                Write-Err "Invalid choice."
                Sign-WithSoftwareCertInteractive
                return
            }
        }
    }
    else {
        Write-Host "Available certificates:"
        Write-Host ""
        $i = 1
        foreach ($f in $p12Files) {
            Write-Host "  $i) $($f.Name)"
            $i++
        }
        Write-Host "  $i) Enter a different path"
        $i++
        Write-Host "  $i) Back to main menu"
        Write-Host ""
        $certNum = Read-Host "Select certificate [1-$i]"

        if ($certNum -eq ($i - 1).ToString()) {
            $p12File = Read-Host "Enter full path to .p12 or .pfx file"
        }
        elseif ($certNum -eq $i.ToString()) {
            Show-InteractiveMenu
            return
        }
        elseif ([int]$certNum -ge 1 -and [int]$certNum -le $p12Files.Count) {
            $p12File = $p12Files[[int]$certNum - 1].FullName
        }
        else {
            Write-Err "Invalid choice."
            Sign-WithSoftwareCertInteractive
            return
        }
    }

    # Select PDF file
    $pdfFile = Select-PdfFile
    if (-not $pdfFile) {
        Show-InteractiveMenu
        return
    }

    # Get password
    Write-Host ""
    $password = Read-Host "Enter certificate password" -AsSecureString
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )

    # Sign the PDF
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($pdfFile)
    $directory = Split-Path -Parent $pdfFile
    if (-not $directory) { $directory = "." }
    $outputPdf = Join-Path $directory "${baseName}_signed.pdf"

    Sign-WithP12 $pdfFile $outputPdf $p12File $passwordPlain

    Pause-Continue
    Show-InteractiveMenu
}

function Sign-WithSmartCardInteractive {
    Write-Host ""
    Write-Warn "Smart Card Signing"
    Write-Host ""

    # First, try Windows Certificate Store (works without OpenSC if Windows recognizes the card)
    $winCerts = Get-WindowsSigningCertificates
    if ($winCerts -and $winCerts.Count -gt 0) {
        Write-Success "Found certificates in Windows Certificate Store!"
        Write-Host ""
        Write-Host "This method works with your existing Windows smart card setup."
        Write-Host "No additional software (OpenSC) is required."
        Write-Host ""

        # List certificates
        $i = 1
        foreach ($cert in $winCerts) {
            $subject = $cert.Subject
            $issuer = $cert.Issuer -replace ".*CN=([^,]+).*", '$1'
            $expires = $cert.NotAfter.ToString("yyyy-MM-dd")
            # Get EKU to help identify certificate purpose
            $ekuList = @()
            if ($cert.EnhancedKeyUsageList) {
                $ekuList = $cert.EnhancedKeyUsageList | ForEach-Object { $_.FriendlyName }
            }
            $ekuStr = if ($ekuList.Count -gt 0) { $ekuList -join ", " } else { "General Purpose" }

            Write-Host "  $i) $subject"
            Write-Host "     Issuer: $issuer | Expires: $expires"
            Write-Host "     Usage: $ekuStr"
            Write-Host ""
            $i++
        }
        Write-Host "  $i) Use OpenSC/PKCS#11 instead"
        $i++
        Write-Host "  $i) Back to main menu"
        Write-Host ""
        $certChoice = Read-Host "Select certificate [1-$i]"

        if ($certChoice -eq ($i - 1).ToString()) {
            # Fall through to OpenSC method
            Sign-WithSmartCardOpenSC
            return
        }
        elseif ($certChoice -eq $i.ToString()) {
            Show-InteractiveMenu
            return
        }
        elseif ([int]$certChoice -ge 1 -and [int]$certChoice -le $winCerts.Count) {
            $selectedCert = $winCerts[[int]$certChoice - 1]

            # Select PDF file
            $pdfFile = Select-PdfFile
            if (-not $pdfFile) {
                Show-InteractiveMenu
                return
            }

            # Sign the PDF
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($pdfFile)
            $directory = Split-Path -Parent $pdfFile
            if (-not $directory) { $directory = "." }
            $outputPdf = Join-Path $directory "${baseName}_signed.pdf"

            $result = Sign-WithWindowsCert $pdfFile $outputPdf $selectedCert.Thumbprint

            if ($result -and (Test-Path $outputPdf)) {
                Write-Host ""
                Write-Success "Successfully signed: $outputPdf"
            }

            Pause-Continue
            Show-InteractiveMenu
            return
        }
        else {
            Write-Err "Invalid choice."
            Sign-WithSmartCardInteractive
            return
        }
    }

    # No Windows certs found, try OpenSC
    Sign-WithSmartCardOpenSC
}

function Sign-WithSmartCardOpenSC {
    Write-Host ""
    Write-Warn "OpenSC/PKCS#11 Smart Card Signing"
    Write-Host ""

    # Check if smart card support is available
    if (-not $script:PKCS11Lib) {
        Write-Err "No PKCS#11 library found."
        Write-Host ""
        Write-Host "No signing certificates were found in Windows Certificate Store,"
        Write-Host "and OpenSC is not installed."
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  1) Insert your smart card and try again (if Windows recognizes it)"
        Write-Host "  2) Install OpenSC from: https://github.com/OpenSC/OpenSC/releases"
        Pause-Continue
        Show-InteractiveMenu
        return
    }

    Write-Host "Checking for smart card via OpenSC..."
    if (Get-Command "pkcs11-tool" -ErrorAction SilentlyContinue) {
        $slotInfo = & pkcs11-tool --module $script:PKCS11Lib --list-slots 2>&1
        if ($slotInfo -notmatch "token present") {
            Write-Host ""
            Write-Warn "No smart card detected."
            Write-Host ""
            Write-Host "Please:"
            Write-Host "  1) Insert your PIV/CAC smart card"
            Write-Host "  2) Ensure your card reader is connected"
            Write-Host ""
            $ready = Read-Host "Press Enter when ready, or 'q' to go back"
            if ($ready -eq "q") {
                Show-InteractiveMenu
                return
            }
            Sign-WithSmartCardOpenSC
            return
        }
    }

    Write-Success "Smart card detected!"
    Write-Host ""

    # List certificates
    Write-Host "Certificates on card:"
    if (Get-Command "pkcs11-tool" -ErrorAction SilentlyContinue) {
        & pkcs11-tool --module $script:PKCS11Lib --list-objects --type cert 2>&1
    }
    Write-Host ""

    # Select PDF file
    $pdfFile = Select-PdfFile
    if (-not $pdfFile) {
        Show-InteractiveMenu
        return
    }

    # Sign the PDF
    Sign-Pdf $pdfFile

    Pause-Continue
    Show-InteractiveMenu
}

function Select-PdfFile {
    Write-Host ""
    $pdfFiles = @(Get-ChildItem -Filter "*.pdf" -ErrorAction SilentlyContinue)

    if ($pdfFiles.Count -eq 0) {
        Write-Warn "No PDF files found in current directory."
        $pdfFile = Read-Host "Enter full path to PDF file"
        return $pdfFile
    }

    Write-Host "Available PDF files:"
    Write-Host ""
    $i = 1
    foreach ($f in $pdfFiles) {
        if ($f.Name -match "_signed\.pdf$") {
            Write-Host "  $i) $($f.Name)" -ForegroundColor Green -NoNewline
            Write-Host " (signed)"
        }
        else {
            Write-Host "  $i) $($f.Name)"
        }
        $i++
    }
    Write-Host "  $i) Enter a different path"
    Write-Host ""
    $pdfNum = Read-Host "Select PDF [1-$i]"

    if ($pdfNum -eq $i.ToString()) {
        return Read-Host "Enter full path to PDF file"
    }
    elseif ([int]$pdfNum -ge 1 -and [int]$pdfNum -le $pdfFiles.Count) {
        return $pdfFiles[[int]$pdfNum - 1].FullName
    }
    else {
        Write-Err "Invalid choice."
        return $null
    }
}

function Verify-Interactive {
    Write-Host ""
    $pdfFile = Select-PdfFile
    if (-not $pdfFile) {
        Show-InteractiveMenu
        return
    }

    Verify-Pdf $pdfFile

    Pause-Continue
    Show-InteractiveMenu
}

# Main script
Test-Tools | Out-Null
Find-PKCS11Library | Out-Null
Test-WindowsSmartCard | Out-Null

switch ($Action) {
    "sign" {
        if (-not $Param1) {
            Write-Host ""
            Write-Host "Available PDFs:"
            Get-ChildItem -Filter "*.pdf" -Name 2>$null | ForEach-Object { Write-Host "  $_" }
            Write-Host ""
            $Param1 = Read-Host "Enter PDF filename to sign"
        }
        Sign-Pdf $Param1
    }
    "sign-p12" {
        if (-not $Param1 -or -not $Param2) {
            Write-Err "Usage: .\sign.ps1 sign-p12 <cert.p12> <file.pdf>"
            exit 1
        }
        if (-not (Test-Path $Param1)) {
            Write-Err "Certificate file not found: $Param1"
            exit 1
        }
        if (-not (Test-Path $Param2)) {
            Write-Err "PDF file not found: $Param2"
            exit 1
        }
        $password = Read-Host "Enter certificate password" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        )
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Param2)
        $directory = Split-Path -Parent $Param2
        if (-not $directory) { $directory = "." }
        $outputPdf = Join-Path $directory "${baseName}_signed.pdf"
        Sign-WithP12 $Param2 $outputPdf $Param1 $passwordPlain
    }
    "verify" {
        if (-not $Param1) {
            Write-Host ""
            $Param1 = Read-Host "Enter PDF filename to verify"
        }
        Verify-Pdf $Param1
    }
    "list" {
        Get-SmartCardCertificates
    }
    "create-cert" {
        Create-TestCertificate
    }
    default {
        Show-InteractiveMenu
    }
}
