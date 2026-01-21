@echo off
setlocal enabledelayedexpansion

:: DecisionDocument Build Script for Windows
:: Builds LaTeX templates to PDF

echo.
echo ========================================
echo   Decision Document Builder
echo ========================================
echo.

:: Check if pdflatex is available
where pdflatex >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: pdflatex not found.
    echo.
    echo MiKTeX is required to build PDF documents.
    echo.
    echo For airgapped systems:
    echo   Download MiKTeX installer from https://miktex.org/download
    echo   on a connected system, transfer via USB, then install.
    echo.
    echo After installing MiKTeX:
    echo   1. Restart this command prompt
    echo   2. Run build.bat again
    echo.
    pause
    exit /b 1
)

:: Determine what to build
set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=both"

:: Validate target
if /i not "%TARGET%"=="decision_memo" if /i not "%TARGET%"=="decision_document" if /i not "%TARGET%"=="both" (
    echo Usage: build.bat [decision_memo^|decision_document^|both]
    echo.
    echo   decision_memo     - Build only decision_memo.pdf
    echo   decision_document - Build only decision_document.pdf
    echo   both              - Build both documents (default)
    exit /b 1
)

:: Build function
:build_doc
if /i "%TARGET%"=="decision_memo" goto :build_memo
if /i "%TARGET%"=="decision_document" goto :build_document
if /i "%TARGET%"=="both" goto :build_both
goto :end

:build_both
call :compile decision_memo
call :compile decision_document
goto :end

:build_memo
call :compile decision_memo
goto :end

:build_document
call :compile decision_document
goto :end

:compile
set "DOCNAME=%~1"
echo Building %DOCNAME%.pdf...
echo.

:: Check if .tex file exists
if not exist "%DOCNAME%.tex" (
    echo ERROR: %DOCNAME%.tex not found!
    exit /b 1
)

:: Run pdflatex 3 times for TOC and references
for /L %%i in (1,1,3) do (
    echo   Pass %%i of 3...
    pdflatex -interaction=nonstopmode "%DOCNAME%.tex" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo ERROR: pdflatex failed on pass %%i
        echo Run manually for details: pdflatex %DOCNAME%.tex
        exit /b 1
    )
)

:: Clean up auxiliary files
echo   Cleaning up...
del /q "%DOCNAME%.aux" 2>nul
del /q "%DOCNAME%.log" 2>nul
del /q "%DOCNAME%.out" 2>nul
del /q "%DOCNAME%.toc" 2>nul
del /q "%DOCNAME%.fdb_latexmk" 2>nul
del /q "%DOCNAME%.fls" 2>nul
del /q "%DOCNAME%.synctex.gz" 2>nul

echo   Done: %DOCNAME%.pdf
echo.
exit /b 0

:end
echo ========================================
echo   Build complete!
echo ========================================
echo.
echo Output files:
if /i "%TARGET%"=="decision_memo" echo   - decision_memo.pdf
if /i "%TARGET%"=="decision_document" echo   - decision_document.pdf
if /i "%TARGET%"=="both" (
    echo   - decision_memo.pdf
    echo   - decision_document.pdf
)
echo.
echo To sign a PDF, run: sign.bat
echo.
