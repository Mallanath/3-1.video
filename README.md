# 3VC.Video — Triple Vertical Player

1 × 3 synced video wall for 9:16 vertical videos. One file plays across all
three panes in sync — column 1 is the master, columns 2–3 stay frame-locked.

## Run (Windows)

```bat
pip install -r requirements.txt
python app.py
```

## Build the exe

```bat
build_exe.bat
```

Output: `dist\TripleVerticalPlayer.exe` (no install needed, Windows 10/11).

## Controls

| Button / key | What it does |
|---|---|
| Open video(s) | Pick file(s) — a single file queues its whole folder |
| Open folder | Every video in the folder plays continuously |
| Play (Space) | Play / pause all 3 panes |
| Sync | Force-resync slaves to master |
| Fullscreen (F) | Borderless fullscreen, UI auto-hides |
| Hide UI (H) | Hide panels for a pure video wall |
| Same view | Reset zoom/pan so all 3 show the identical frame |
| Prev / Next (P / N) | Step through the queue |
| Loop | ON = repeat the same video · OFF = play queue once |

Quality is lossless — original file bytes are streamed as-is, and at 1× zoom
no CSS transform is applied, so frames render pixel-for-pixel.
