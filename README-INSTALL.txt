Triple Vertical Player - EASY INSTALL (for any Windows 10/11 laptop)
===============================================================

You need NOTHING installed first. No Python. No admin rights.

OPTION A - Setup file (easiest, if you got it):
  1. Double-click  TripleVerticalPlayer-Setup.exe
  2. Click Next / Install (no admin prompt appears - that is normal)
  3. Done. Use the "Triple Vertical Player" Desktop / Start Menu icon.
  The app does NOT pop up after install - start it yourself when ready.

OPTION B - Portable ZIP (if you got the .zip):
  1. Unzip  TripleVerticalPlayer-Portable.zip  anywhere
  2. Double-click  Install.bat  (creates Desktop + Start Menu icons)
     - or skip Install.bat and just double-click TripleVerticalPlayer.exe
  3. If Windows SmartScreen says "Unknown publisher": click
     More info -> Run anyway. (Normal for a new exe.)

FIRST-RUN NOTE (one time only):
  The player needs the free "Microsoft Edge WebView2 Runtime".
  Most laptops already have it. If the app says it is missing:
    1. Go to: https://developer.microsoft.com/microsoft-edge/webview2/
    2. Download + install the Runtime (2 minutes)
    3. Start the player again. Done forever.

UNINSTALL:
  - Setup install: Settings -> Apps -> Triple Vertical Player -> Uninstall
  - Portable: delete the folder + Desktop icon. Nothing else was changed.

TROUBLESHOOTING ("not working" fixes built into this version):
  - Double-click does nothing, no error?
    -> You are missing WebView2 (see above). The app now tells you
       instead of staying silent.
  - Antivirus blocks/quarantines the exe?
    -> It is a false positive on fresh PyInstaller exes. Restore the
       file in your antivirus, or use the Setup.exe build.
  - Right-click exe -> Properties -> tick "Unblock" if Windows blocked
    a file downloaded from the internet.
  - Videos won't play (black screen)?
    -> Convert to MP4 (H.264) / WebM / MOV. Some AVI/WMV/MKV codecs
       are not supported by WebView2.
