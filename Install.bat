@echo off
REM ============================================================
REM  Triple Vertical Player - INSTALL for other laptops
REM  (no Python needed, no admin needed, never opens the app)
REM
REM  HOW TO USE:
REM    1. Copy this file + TripleVerticalPlayer.exe into ONE folder
REM       (that is exactly what TripleVerticalPlayer-Portable.zip has)
REM    2. Double-click Install.bat
REM    3. Done - use the Desktop / Start Menu icon.
REM ============================================================
setlocal
cd /d "%~dp0"

echo Installing Triple Vertical Player (no admin needed)...

if not exist "TripleVerticalPlayer.exe" (
  echo.
  echo [ERROR] TripleVerticalPlayer.exe not found next to Install.bat.
  echo Put both files in the same folder and try again.
  echo.
  pause
  exit /b 1
)

set DEST=%LocalAppData%\TripleVerticalPlayer
if not exist "%DEST%" mkdir "%DEST%" 2>nul
copy /y "TripleVerticalPlayer.exe" "%DEST%\TripleVerticalPlayer.exe" >nul
if errorlevel 1 (
  echo [ERROR] Copy failed. The file may be blocked - right-click it
  echo ^> Properties ^> check "Unblock" ^> OK, then run Install again.
  pause
  exit /b 1
)

REM --- Desktop + Start Menu shortcuts (PowerShell, no extra tools) ---
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$env:USERPROFILE\Desktop\Triple Vertical Player.lnk\");" ^
  "$s.TargetPath=\"$env:LocalAppData\TripleVerticalPlayer\TripleVerticalPlayer.exe\";" ^
  "$s.WorkingDirectory=\"$env:LocalAppData\TripleVerticalPlayer\";" ^
  "$s.Description=\"Triple Vertical Player - 1x3 synced video wall\";" ^
  "$s.Save();"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$m=\"$env:AppData\Microsoft\Windows\Start Menu\Programs\";" ^
  "if(!(Test-Path $m)){New-Item -ItemType Directory -Path $m -Force|Out-Null};" ^
  "$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$m\Triple Vertical Player.lnk\");" ^
  "$s.TargetPath=\"$env:LocalAppData\TripleVerticalPlayer\TripleVerticalPlayer.exe\";" ^
  "$s.WorkingDirectory=\"$env:LocalAppData\TripleVerticalPlayer\";" ^
  "$s.Description=\"Triple Vertical Player - 1x3 synced video wall\";" ^
  "$s.Save();"

echo.
echo ================================================
echo  INSTALLED. The app was NOT opened (by design).
echo  Start it from the Desktop icon "Triple Vertical Player".
echo.
echo  First run needs WebView2 (free, from Microsoft).
echo  If the app tells you it is missing, install it once
echo  from: https://developer.microsoft.com/microsoft-edge/webview2/
echo ================================================
echo  This window closes automatically in 6 seconds...
timeout /t 6 /nobreak >nul
exit /b 0
