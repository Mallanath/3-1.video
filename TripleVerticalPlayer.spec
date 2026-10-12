# -*- mode: python ; coding: utf-8 -*-
# TripleVerticalPlayer - PyInstaller spec.
# Fixed for "works on any laptop":
#  - explicit hiddenimports so the exe never depends on the build PC's
#    site-packages layout (missing clr/pythonnet/webview = silent fail).
#  - upx=False: UPX packing is the classic cause of "works here, blocked
#    or corrupt on another laptop" (antivirus heuristics + old CPUs).
#  - console=False: no black console window next to the player.
#  - onefile: single TripleVerticalPlayer.exe, nothing else to install.
#
# Build with:  build_exe.bat   (uses this spec, never launches the app)

a = Analysis(
    ['app.py'],
    pathex=[],
    binaries=[],
    datas=[('index.html', '.')],
    hiddenimports=[
        'webview',
        'webview.platforms.winforms',
        'webview.platforms.edgechromium',
        'clr_loader',
        'pythonnet',
        'cffi',
        'bottle',
        'proxy_tools',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    # Trim dead weight only - never exclude anything webview might need.
    excludes=['tkinter', 'unittest', 'pydoc', 'doctest'],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='TripleVerticalPlayer',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
