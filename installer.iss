; ============================================================
; Triple Vertical Player - Inno Setup script (Inno Setup 6)
; Builds: Output\TripleVerticalPlayer-Setup.exe
; Build it with:  Build-Installer.bat   (never launches the app)
;
; Design choices that fix "not working on other laptops":
;  - PrivilegesRequired=lowest  -> NO admin prompt, installs even on
;    locked-down / office / school laptops.
;  - Installs to LocalAppData   -> no Program Files permission issues.
;  - No Python / pip needed on the target PC at all.
;  - Setup NEVER auto-launches the app (no surprise window).
;  - Warns when WebView2 Runtime is missing, with one-click download.
; ============================================================

#define MyAppName "Triple Vertical Player"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "TripleVerticalPlayer"
#define MyAppExeName "TripleVerticalPlayer.exe"

[Setup]
AppId={{8E2B4A1C-3F7D-4A9E-B5C2-1D0F6A9E4B7C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\TripleVerticalPlayer
DefaultGroupName={#MyAppName}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=Output
OutputBaseFilename=TripleVerticalPlayer-Setup
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
MinVersion=10.0
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayName={#MyAppName}
; Never start the app after install (user asked: no surprise app window)
DisableFinishedPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

; Double-click a video -> Open With -> TripleVerticalPlayer still works
; because app.py queues the dropped file's whole folder. No forced
; file-association takeover (that is what breaks installs for many users).

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function IsWebView2Installed: Boolean;
begin
  Result := RegKeyExists(HKLM,
    'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}')
    or RegKeyExists(HKLM,
    'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}')
    or RegKeyExists(HKCU,
    'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}')
    or DirExists('C:\Program Files (x86)\Microsoft\EdgeWebView\Application');
end;

function InitializeSetup: Boolean;
var
  Res: Integer;
begin
  Result := True;
  if not IsWebView2Installed then
  begin
    Res := MsgBox(
      'Microsoft Edge WebView2 Runtime was not found on this PC.' + #13#10 + #13#10 +
      'Triple Vertical Player needs it once (free, from Microsoft).' + #13#10 +
      'You can install the player now and add WebView2 afterwards.' + #13#10 + #13#10 +
      'Open the WebView2 download page now?',
      mbConfirmation, MB_YESNO);
    if Res = IDYES then
      ShellExec('open', 'https://developer.microsoft.com/microsoft-edge/webview2/#download-section',
        '', '', SW_SHOW, ewNoWait, Res);
    { Continue install either way - the app itself re-checks at startup. }
  end;
end;
