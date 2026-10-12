"""Triple Vertical Player - desktop wrapper (1x3 synced video wall).

Runs triple-vertical-player/index.html inside a native window using
pywebview (Edge WebView2 on Windows).

Notes:
- File picking uses the page's own <input type=file> / webkitdirectory
  inputs: WebView2 shows its native picker for those, no permission popups.
  (pywebview's Window.create_file_dialog does not exist on the
  edgechromium backend, so dialogs are NOT routed through Python.)
- Videos passed on the command line (drag onto exe / "Open with") auto-load
  via Api.get_startup, streamed from Python over a local http://127.0.0.1
  server with Range-request support so seeking works.

Build exe (Windows):
    pip install pywebview pyinstaller
    pyinstaller --noconfirm --onefile --windowed --name TripleVerticalPlayer --add-data "index.html;." app.py
    -> dist/TripleVerticalPlayer.exe
"""
import itertools
import mimetypes
import pathlib
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

try:
    import webview
except ImportError:  # friendly message when deps are missing
    print("pywebview is not installed. Run: pip install pywebview")
    sys.exit(1)

VIDEO_EXTS = (
    ".mp4", ".m4v", ".webm", ".mov", ".mkv", ".avi",
    ".mpg", ".mpeg", ".ogv", ".flv", ".wmv", ".ts",
    ".m2ts", ".mts", ".3gp",
)
MIME_OVERRIDES = {
    ".mkv": "video/x-matroska",
    ".m2ts": "video/mp2t",
    ".mts": "video/mp2t",
    ".ts": "video/mp2t",
    ".ogv": "video/ogg",
    ".flv": "video/x-flv",
    ".wmv": "video/x-ms-wmv",
    ".avi": "video/x-msvideo",
    ".mov": "video/quicktime",
}

# token -> absolute Path, served at /v/<token>
_registry = {}
_token_seq = itertools.count(1)


def register(path: pathlib.Path) -> str:
    token = str(next(_token_seq))
    _registry[token] = path
    return token


def video_files_in(folder: pathlib.Path):
    try:
        entries = list(folder.iterdir())
    except OSError:
        return []
    return sorted(
        (p for p in entries if p.is_file() and p.suffix.lower() in VIDEO_EXTS),
        key=lambda p: p.name.lower(),
    )


class VideoHandler(BaseHTTPRequestHandler):
    server_version = "TripleWall/1.0"

    def log_message(self, *args):  # keep the console clean
        pass

    def _send_file(self, head_only=False):
        token = unquote(urlsplit(self.path).path)
        if not token.startswith("/v/"):
            self.send_error(404)
            return
        path = _registry.get(token[3:])
        if path is None or not path.is_file():
            self.send_error(404)
            return
        try:
            size = path.stat().st_size
        except OSError:
            self.send_error(404)
            return
        ctype = MIME_OVERRIDES.get(
            path.suffix.lower(),
            mimetypes.guess_type(str(path))[0] or "application/octet-stream",
        )
        start, end = 0, size - 1
        ranged = False
        range_h = self.headers.get("Range")
        if range_h and range_h.startswith("bytes="):
            try:
                spec = range_h[6:].split(",")[0].strip()
                if spec.startswith("-"):
                    start = max(0, size - int(spec[1:]))
                else:
                    a, _, b = spec.partition("-")
                    start = int(a)
                    if b:
                        end = min(int(b), size - 1)
                if 0 <= start < size and start <= end:
                    ranged = True
                else:
                    self.send_response(416)
                    self.send_header("Content-Range", f"bytes */{size}")
                    self.end_headers()
                    return
            except (ValueError, IndexError):
                start, end = 0, size - 1
        length = end - start + 1
        try:
            self.send_response(206 if ranged else 200)
            self.send_header("Content-Type", ctype)
            self.send_header("Accept-Ranges", "bytes")
            if ranged:
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(length))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            if head_only:
                return
            with open(path, "rb") as f:
                f.seek(start)
                remaining = length
                while remaining > 0:
                    chunk = f.read(min(262144, remaining))
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    remaining -= len(chunk)
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            pass  # user skipped to another video; harmless

    def do_GET(self):
        self._send_file(head_only=False)

    def do_HEAD(self):
        self._send_file(head_only=True)


class Api:
    """Called from JS (pywebview runs these on a worker thread).

    - get_startup: pure filesystem work, no UI.
    - toggle_fullscreen: BrowserForm.toggle_fullscreen marshals to the UI
      thread itself via Control.Invoke.
    - pick_files / pick_folder: native Windows file dialogs via
      Window.create_file_dialog (reliable, works without a user-gesture
      restriction, so the app can auto-open the chooser on launch).
      The HTML <input type=file> pickers remain as a browser fallback.
    """

    def __init__(self):
        self.base = ""

    def _pack(self, paths, index=0):
        urls, names = [], []
        for p in paths:
            p = pathlib.Path(p)
            if p.is_file():
                urls.append(f"{self.base}/v/{register(p.resolve())}")
                names.append(p.name)
        return {"urls": urls, "names": names, "index": max(0, min(index, len(urls) - 1)) if urls else 0}

    def toggle_fullscreen(self):
        wins = webview.windows
        if not wins:
            return False
        form = getattr(wins[0], "native", None)
        if form is None:
            return False
        form.toggle_fullscreen()  # thread-safe: marshals via Control.Invoke
        try:
            return bool(form.is_fullscreen)
        except Exception:
            return False

    def pick_files(self):
        """Native Open-video dialog. Returns packed http urls or None."""
        try:
            wins = webview.windows
            if not wins:
                return None
            file_types = (
                "Video files (*.mp4;*.m4v;*.webm;*.mov;*.mkv;*.avi;*.mpg;*.mpeg;*.ogv;*.flv;*.wmv;*.ts;*.m2ts;*.mts;*.3gp)",
                "All files (*.*)",
            )
            result = wins[0].create_file_dialog(
                webview.FileDialog.OPEN, allow_multiple=True, file_types=file_types
            )
        except Exception:
            return None
        if not result:
            return None
        vids = [pathlib.Path(p) for p in result if pathlib.Path(p).suffix.lower() in VIDEO_EXTS]
        if not vids:
            return None
        if len(vids) == 1 and vids[0].is_file():
            # Single file picked: queue the whole folder so ⏮ ⏭ / N / P
            # step through sibling videos (same as drag-onto-exe behavior).
            folder = vids[0].parent
            sibs = video_files_in(folder)
            if sibs:
                try:
                    idx = sibs.index(vids[0].resolve())
                except ValueError:
                    idx = 0
                return self._pack(sibs, idx)
        return self._pack(sorted(vids, key=lambda p: p.name.lower()), 0)

    def pick_folder(self):
        """Native Open-folder dialog. Returns packed http urls or None."""
        try:
            wins = webview.windows
            if not wins:
                return None
            result = wins[0].create_file_dialog(webview.FileDialog.FOLDER)
        except Exception:
            return None
        if not result:
            return None
        paths = []
        for f in result:
            folder = pathlib.Path(f)
            if folder.is_dir():
                paths.extend(video_files_in(folder))
        if not paths:
            return None
        return self._pack(paths, 0)

    def get_startup(self):
        """Files/folders passed on the command line (drag onto exe / Open with)."""
        args = [pathlib.Path(a) for a in sys.argv[1:] if not a.startswith("-")]
        if not args:
            return None
        if len(args) == 1 and args[0].is_file():
            # Queue the whole folder so it plays continuously from this file.
            folder = args[0].parent
            vids = video_files_in(folder)
            if vids:
                try:
                    idx = vids.index(args[0].resolve())
                except ValueError:
                    idx = 0
                return self._pack(vids, idx)
            return self._pack([args[0]], 0)
        paths = []
        for a in args:
            if a.is_file():
                paths.append(a)
            elif a.is_dir():
                paths.extend(video_files_in(a))
        if not paths:
            return None
        return self._pack(paths, 0)


def find_index_html() -> pathlib.Path:
    candidates = []
    if hasattr(sys, "_MEIPASS"):
        candidates.append(pathlib.Path(sys._MEIPASS) / "index.html")
    here = pathlib.Path(__file__).resolve().parent
    candidates.append(here / "index.html")
    candidates.append(pathlib.Path.cwd() / "index.html")
    for p in candidates:
        if p.is_file():
            return p
    raise FileNotFoundError(
        'index.html not found next to app.py. Keep index.html beside app.py '
        'or rebuild the exe with --add-data "index.html;."'
    )


def main() -> None:
    server = ThreadingHTTPServer(("127.0.0.1", 0), VideoHandler)
    server.daemon_threads = True
    port = server.server_address[1]
    threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.2}, daemon=True).start()

    api = Api()
    api.base = f"http://127.0.0.1:{port}"

    index = find_index_html()
    webview.create_window(
        "Triple Vertical Player - 9:16 x3 Synced",
        url=index.as_uri(),
        width=1280,
        height=860,
        resizable=True,
        text_select=False,
        js_api=api,
        background_color="#000000",  # WebView2 + window chrome stay black: no white edge lines
    )
    webview.start(gui="edgechromium", debug=False)


if __name__ == "__main__":
    main()
