@echo off
REM Build TripleVerticalPlayer.exe (Windows, one-file, windowed)
REM Run this from the triple-vertical-player folder.
pip install -r requirements.txt
pyinstaller --noconfirm --onefile --windowed --name TripleVerticalPlayer --add-data "index.html;." app.py
echo.
echo Done. Your exe is at: dist\TripleVerticalPlayer.exe
pause
