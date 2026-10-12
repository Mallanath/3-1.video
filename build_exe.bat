@echo off
REM ============================================================
REM  TripleVerticalPlayer - one-click BUILD (developer PC only)
REM  Double-click this file -> builds dist\TripleVerticalPlayer.exe
REM  It NEVER launches the app. The window closes itself when done.
REM ============================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ================================================
echo  TripleVerticalPlayer - building exe...
echo  (this only BUILDS, it does NOT open the app)
echo ================================================

REM --- 1. Python check ---
python --version >nul 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Python not found.
  echo Install Python 3.10+ from https://www.python.org/downloads/
  echo IMPORTANT: tick "Add python.exe to PATH" during install.
  echo.
  pause
  exit /b 1
)

REM --- 2. Files check ---
if not exist "app.py" (
  echo [ERROR] app.py not found. Run this bat from the triple-vertical-player folder.
  pause
  exit /b 1
)
if not exist "index.html" (
  echo [ERROR] index.html not found next to app.py.
  pause
  exit /b 1
)

REM --- 3. Install deps (quiet, no app launch) ---
echo [1/3] Installing dependencies...
python -m pip install --upgrade pip >nul 2>&1
python -m pip install -r requirements.txt
if errorlevel 1 (
  echo.
  echo [ERROR] pip install failed. Check your internet connection and try again.
  echo.
  pause
  exit /b 1
)

REM --- 4. Build exe via spec (never runs the app) ---
echo [2/3] Building exe with PyInstaller...
python -m PyInstaller --noconfirm --clean TripleVerticalPlayer.spec
if errorlevel 1 (
  echo.
  echo [ERROR] PyInstaller build failed. See messages above.
  echo.
  pause
  exit /b 1
)

REM --- 5. Verify output ---
echo [3/3] Verifying...
if not exist "dist\TripleVerticalPlayer.exe" (
  echo.
  echo [ERROR] Build finished but dist\TripleVerticalPlayer.exe is missing.
  echo.
  pause
  exit /b 1
)

for %%F in ("dist\TripleVerticalPlayer.exe") do set SIZE=%%~zF
echo.
echo ================================================
echo  BUILD OK - app was NOT launched (by design).
echo.
echo  Exe : dist\TripleVerticalPlayer.exe (%SIZE% bytes^)
echo  Next: double-click the exe to run, or run
echo        Build-Installer.bat to make the Setup for
echo        other laptops.
echo ================================================
echo  This window closes automatically in 5 seconds...
timeout /t 5 /nobreak >nul
exit /b 0
