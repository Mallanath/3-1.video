@echo off
REM ============================================================
REM  TripleVerticalPlayer - one-click INSTALLER BUILD
REM  Double-click -> 1) builds exe  2) makes ZIP + Setup.exe
REM  It NEVER launches the app.
REM  Give the resulting Setup/ZIP to other laptops - they need
REM  NO Python, NO pip, NO build step.
REM ============================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo ================================================
echo  Building exe + installer (app will NOT open)...
echo ================================================

REM --- Step 1: build the exe (inline, so we never launch anything) ---
call "%~dp0build_exe.bat"
if errorlevel 1 (
  echo [ERROR] exe build failed - installer aborted.
  pause
  exit /b 1
)
REM build_exe.bat auto-closes on success, but when CALLED it returns here.
REM Re-verify exe exists (build_exe already checked, this is belt+suspenders).
if not exist "dist\TripleVerticalPlayer.exe" (
  echo [ERROR] dist\TripleVerticalPlayer.exe missing after build.
  pause
  exit /b 1
)

echo.
echo [4/4] Making installer package...

REM --- Step 2: portable ZIP (always works, no tools needed) ---
set ZIPOUT=TripleVerticalPlayer-Portable.zip
if exist "%ZIPOUT%" del /q "%ZIPOUT%"
powershell -NoProfile -Command "Compress-Archive -LiteralPath 'dist\TripleVerticalPlayer.exe','README.md' -DestinationPath '%ZIPOUT%' -Force"
if exist "%ZIPOUT%" (
  echo   ZIP OK: %ZIPOUT%
) else (
  echo   [WARN] ZIP creation failed - Setup below still works.
)

REM --- Step 3: proper Setup.exe via Inno Setup (if installed) ---
set ISCC=
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set ISCC=C:\Program Files\Inno Setup 6\ISCC.exe
where iscc >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%I in ('where iscc') do set ISCC=%%I
)

if defined ISCC (
  echo   Found Inno Setup: !ISCC!
  "%ISCC%" installer.iss
  if errorlevel 1 (
    echo   [WARN] Inno build failed - use the Portable ZIP instead.
  ) else (
    echo   Setup OK: see Output\ folder.
  )
) else (
  echo.
  echo   NOTE: Inno Setup not installed, so no Setup.exe was made.
  echo   You still have: %ZIPOUT%  - copy it to the other laptop,
  echo   unzip, double-click TripleVerticalPlayer.exe. No install needed.
  echo.
  echo   For a real Setup.exe with desktop icon + uninstaller:
  echo     1) Install free Inno Setup 6: https://jrsoftware.org/isdl.php
  echo     2) Run Build-Installer.bat again.
)

echo.
echo ================================================
echo  DONE - app was NOT launched (by design).
echo  Share with other laptops:
echo    - TripleVerticalPlayer-Portable.zip  (works everywhere)
echo    - Output\TripleVerticalPlayer-Setup.exe (if Inno was found)
echo  On the other laptop: unzip or run Setup, double-click
echo  the app - NO Python needed there.
echo ================================================
echo  This window closes automatically in 8 seconds...
timeout /t 8 /nobreak >nul
exit /b 0
