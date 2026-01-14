@echo off
setlocal enabledelayedexpansion

:: DecisionDocument Sign Script for Windows
:: Signs PDF documents using PdfSigner.exe

set "SCRIPTDIR=%~dp0"

:: Check if PdfSigner.exe exists
if not exist "%SCRIPTDIR%PdfSigner.exe" (
    echo ERROR: PdfSigner.exe not found!
    echo Expected location: %SCRIPTDIR%PdfSigner.exe
    pause
    exit /b 1
)

:: Parse command
set "CMD=%~1"

if "%CMD%"=="" goto :menu
if /i "%CMD%"=="verify" goto :verify
if /i "%CMD%"=="create-cert" goto :create_cert
if /i "%CMD%"=="list" goto :list

:: Assume it's a file to sign
if exist "%CMD%" (
    "%SCRIPTDIR%PdfSigner.exe" "%CMD%" --gui
    goto :end
)

echo ERROR: Unknown command or file not found: %CMD%
echo.
echo Usage: sign.bat [command] [options]
echo.
echo Commands:
echo   sign.bat                    Interactive mode
echo   sign.bat file.pdf           Sign a PDF
echo   sign.bat verify file.pdf    Verify a signed PDF
echo   sign.bat create-cert        Create a test certificate
echo   sign.bat list               List available certificates
echo.
pause
exit /b 1

:menu
echo.
echo ========================================
echo   Decision Document Signer
echo ========================================
echo.
echo   [1] Sign a PDF
echo   [2] Verify a signed PDF
echo   [3] Create test certificate
echo   [4] List certificates
echo   [0] Exit
echo.
set /p choice="Enter choice: "

if "%choice%"=="0" exit /b 0
if "%choice%"=="1" goto :sign_menu
if "%choice%"=="2" goto :verify_menu
if "%choice%"=="3" goto :create_cert
if "%choice%"=="4" goto :list
goto :menu

:sign_menu
echo.
echo Available PDFs to sign:
echo.
set "count=0"
for %%f in (*.pdf) do (
    echo %%f | findstr /i "_signed.pdf" >nul
    if !ERRORLEVEL! neq 0 (
        set /a count+=1
        echo   [!count!] %%f
        set "file!count!=%%f"
    )
)

if %count%==0 (
    echo   No unsigned PDFs found.
    echo   Run build.bat first to generate PDFs.
    echo.
    pause
    goto :menu
)

echo.
echo   [0] Back
echo.
set /p fchoice="Enter choice: "

if "%fchoice%"=="0" goto :menu
set /a fnum=%fchoice% 2>nul
if %fnum% lss 1 goto :sign_menu
if %fnum% gtr %count% goto :sign_menu

call set "selected=%%file%fnum%%%"
echo.
echo Signing: %selected%
echo.
"%SCRIPTDIR%PdfSigner.exe" "%selected%" --gui
echo.
pause
goto :menu

:verify_menu
echo.
echo Signed PDFs:
echo.
set "count=0"
for %%f in (*_signed.pdf) do (
    set /a count+=1
    echo   [!count!] %%f
    set "file!count!=%%f"
)

if %count%==0 (
    echo   No signed PDFs found.
    echo.
    pause
    goto :menu
)

echo.
echo   [0] Back
echo.
set /p vchoice="Enter choice: "

if "%vchoice%"=="0" goto :menu
set /a vnum=%vchoice% 2>nul
if %vnum% lss 1 goto :verify_menu
if %vnum% gtr %count% goto :verify_menu

call set "selected=%%file%vnum%%%"
goto :do_verify

:verify
if "%~2"=="" (
    echo ERROR: No file specified
    echo Usage: sign.bat verify file_signed.pdf
    pause
    exit /b 1
)
set "selected=%~2"

:do_verify
echo.
echo Verifying: %selected%
echo.

:: Check if file exists
if not exist "%selected%" (
    echo ERROR: File not found: %selected%
    pause
    exit /b 1
)

:: Use PdfSigner to verify
"%SCRIPTDIR%PdfSigner.exe" --verify "%selected%"
echo.
pause
goto :menu

:create_cert
echo.
echo ========================================
echo   Create Test Certificate
echo ========================================
echo.

:: Check for openssl
where openssl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: OpenSSL not found.
    echo.
    echo For airgapped systems, download OpenSSL for Windows from:
    echo   https://slproweb.com/products/Win32OpenSSL.html
    echo.
    pause
    goto :menu
)

set /p "NAME=Enter your name: "
if "%NAME%"=="" (
    echo Cancelled.
    goto :menu
)

set /p "ORG=Enter organization: "
if "%ORG%"=="" set "ORG=Test Organization"

set /p "COUNTRY=Enter country code (US): "
if "%COUNTRY%"=="" set "COUNTRY=US"

set /p "PASSWORD=Enter certificate password: "
if "%PASSWORD%"=="" set "PASSWORD=password"

:: Sanitize name for filename
set "SAFENAME=%NAME: =_%"

echo.
echo Creating certificate for: %NAME%
echo Organization: %ORG%
echo Country: %COUNTRY%
echo.

:: Generate key and certificate
openssl req -x509 -newkey rsa:2048 ^
    -keyout "%SAFENAME%_key.pem" ^
    -out "%SAFENAME%_cert.pem" ^
    -days 365 -nodes ^
    -subj "/C=%COUNTRY%/O=%ORG%/CN=%NAME%" ^
    -addext "keyUsage=digitalSignature" ^
    -addext "extendedKeyUsage=emailProtection" 2>nul

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create certificate
    pause
    goto :menu
)

:: Create PKCS#12 bundle
openssl pkcs12 -export ^
    -out "%SAFENAME%.p12" ^
    -inkey "%SAFENAME%_key.pem" ^
    -in "%SAFENAME%_cert.pem" ^
    -passout pass:%PASSWORD%

echo.
echo Certificate created successfully!
echo.
echo Files:
echo   %SAFENAME%_key.pem  - Private key (keep secure!)
echo   %SAFENAME%_cert.pem - Public certificate
echo   %SAFENAME%.p12      - Bundle for signing
echo.
echo Password: %PASSWORD%
echo.
pause
goto :menu

:list
echo.
echo Listing certificates...
echo.
"%SCRIPTDIR%PdfSigner.exe" --list
echo.
pause
goto :menu

:end
echo.
