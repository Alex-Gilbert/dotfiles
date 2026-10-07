# Recording and editing on cachy-two

## Ready now

OBS Studio is already installed as `com.obsproject.Studio` (Flatpak). Native
Blender is 5.2.1; a separate Flatpak Blender 5.0 is also installed. Use the native
`blender` command consistently so projects and add-ons use the same installation.

Sway shortcuts (Hyper = Ctrl+Alt+Shift+Super):

| Shortcut | Action |
| --- | --- |
| Hyper+S | Select region, save PNG in ~/Pictures/screenshots, copy image |
| Hyper+P | Select region, save PNG, open in Pinta to annotate |
| Hyper+R | Select region and record; press again to stop and export |
| Hyper+W | Record the focused window's fixed rectangle; press again to stop |
| Hyper+Z | Toggle 1.5× mouse-follow zoom on/off during recording |
| Hyper+F9 | Desktop monitor: 1920×1080 at 60 Hz, scale 1 |
| Hyper+F10 | Restore desktop monitor: 3840×2160 at 240 Hz, scale 1.5 |

In Pinta, save edits with Ctrl+S or use Save As to keep the original capture.

The display shortcuts live in the desktop host config. Select recording mode
before selecting the OBS screen source. The recorded screen can then map 1:1
onto a 1080p canvas. The 4K monitor still scales the 1080p signal for display;
judge capture sharpness from the recording at 100% zoom. Increase editor/browser
font sizes for readability. Avoid resizing the screen source or capturing
fractionally scaled XWayland apps when text sharpness matters.

## One-shortcut demo recording

Sway now invokes `~/dotfiles/scripts/demo-record`, replacing the old
`~/.local/bin/recscreen` binding. The old command is no longer used by Sway.
Dependencies: Python 3, wf-recorder, FFmpeg/ffprobe, slurp, swaymsg,
notify-send, C/C++ compilers, Meson/Ninja, pkg-config, FFmpeg development libraries,
Wayland client headers, wayland-scanner, and wayland-protocols.
These are installed on this machine. The small native
cursor reader builds into `~/.cache/demo-record/` on first use or source changes.
It uses Sway's ext-image-copy-capture protocol, without grabbing input or opening
an overlay. No new Python packages or permanent background service are needed.

`scripts/build-demo-recorder` builds a private, pinned wf-recorder in that cache.
It captures without painting the cursor and reports the first-frame timestamp.
This matters because stock wf-recorder's cursor painting disables Sway's cursor
telemetry. The build also adapts that release to the installed FFmpeg 9 API.
The system wf-recorder is unchanged. The private build is ready now; if its cache
is cleared, the next recording rebuilds it (requiring internet access).

Select an area with Hyper+R (Escape cancels), or focus an app and use Hyper+W.
Recording starts after a three-second countdown. Waybar shows the elapsed time
and `FOLLOW ON` / `FOLLOW OFF`; click it to stop or right-click to toggle follow.
Press Hyper+Z to zoom toward your mouse and follow it. Press Hyper+Z again to
smoothly zoom back out. There is no time limit: if you stop recording while follow
is on, it stays on through the end of that take. Holding the shortcut does not
repeatedly toggle it. The zoom is added to the exported video; your desktop view
stays unchanged. Toggling produces no notification in the footage.

Each take gets a unique folder under `~/Videos/demos/`:

- `raw.mkv`: cursor-free original H.264 footage at CRF 18, 30 fps, and native capture resolution.
- `project.json`: capture settings and editable zoom-toggle times.
- `cursor.jsonl`: timestamped native pointer positions, used to follow the mouse.
- `demo.mp4`: 1920×1080 H.264 export, CRF 20, with Kanagawa background, padding,
  and a soft shadow. The original aspect ratio is preserved.
- `capture.log` / `cursor.log` / `export.log`: diagnostics if capture or rendering fails.

The original is always retained. An export failure also keeps any previous
successful `demo.mp4`. Waybar shows `EXPORTING` until the automatic export ends;
wait for it to finish before starting another take.

Capture is silent by default. Use an explicit PulseAudio/PipeWire source for audio:

```sh
pactl list short sources
~/dotfiles/scripts/demo-record toggle --window --audio SOURCE_NAME
```

Choose a `.monitor` source for desktop sound, or a microphone source for narration.
For fast motion, add `--fps 60`. Use OBS for simultaneous camera/mic/desktop mixing
and separate audio tracks. Source footage is much larger than the former Reddit
clips; remove unwanted take folders yourself after reviewing the export.

To render again after changing zoom-toggle times:

```sh
~/dotfiles/scripts/demo-record render ~/Videos/demos/TAKE_FOLDER
```

For example, `"zoom_toggles": [2.5, 12, 18]` follows the mouse from 2.5 to 12 seconds,
then from 18 seconds through the end. Keep times sorted; use an empty list for no
zooms. `~/dotfiles/scripts/demo-record zoom` is the CLI equivalent of Hyper+Z.
The former `mark` command is an alias for this toggle. Older recordings with
fixed markers still render with their original behavior.

Window capture records a fixed screen rectangle, including anything that covers
it. Keep the app still and on-screen. Capture must stay within one monitor;
set resolution/scaling before selecting the area and keep it unchanged during
recording. Pointer positions account for monitor scale and capture-region offsets.
The crop stays inside the captured area; leaving the monitor holds the last known
pointer position. The export adds a clear white arrow at the captured pointer
coordinates, synchronized to the exact first-frame clock, and smooths the camera
motion. The source video and pointer data remain separate. Tracking failure stops the take and preserves
the original, instead of silently exporting a centered zoom.

## Finish OBS setup in its window

Launch `flatpak run com.obsproject.Studio`.

1. Profile → Import → choose `~/dotfiles/media/obs-1080p`, then select
   **1080p Editing**. This prepared profile uses a 1920×1080 canvas and output,
   30 fps, 48 kHz stereo, MKV, and Simple Output's Indistinguishable quality.
   Choose the recording folder in Settings → Output before recording.
2. The profile starts with software H.264 for compatibility. If **Hardware
   (NVENC, H.264)** is available, select it and verify a short recording. The
   desktop runs on the AMD iGPU; the installed RTX 5090 is not proof that OBS's
   Flatpak has a usable NVIDIA encoder. H.264 is an easy starting point for edits.
3. Create a scene collection named **Studio**. The existing Untitled collection
   has an XSHM/X11 source. Add **Screen Capture (PipeWire)** and select the Sway
   monitor through the portal. Check the source dimensions and fit to canvas.
4. Create **Screen**, **Camera**, and **Screen + Camera** scenes. Add the C930e as
   **Video Capture Device (V4L2)**, choosing a supported 1920×1080/30 format.
   Reuse the existing camera source across scenes. Put it above the screen source
   for picture-in-picture. Keep the scene transition simple (cut or short fade).
5. For a physical green screen, add **Chroma Key** to the camera source. Light
   the screen evenly, leave distance behind you, then adjust similarity and spill
   reduction while watching hair and moving hands. Lock exposure/white balance
   if the camera offers those controls, after lighting is set.

30 fps is the starting point for talking and demos. Use 60 fps across OBS and
Blender if fast scrolling or motion needs it; verify the webcam's supported
modes separately. Recording a 30 fps camera in a 60 fps project won't add detail.

OBS supports [quality presets and MKV recording](https://obsproject.com/kb/standard-recording-output-guide).
MKV tolerates interrupted recording; use File → Remux Recordings to make an MP4
without another lossy encode if needed by the editing workflow.

## When the Scarlett is plugged in

Run `wpctl status` again and identify the Scarlett model and available inputs.
In OBS, select its input explicitly instead of Default. Disable unused global
microphone inputs so the webcam mic isn't mixed with it. Check the meter and
make a spoken test before starting a session.

For one microphone, verify mono routing: an interface input may otherwise land
only on the left or right channel. Start with peaks around -12 to -6 dBFS, leave
headroom, and use the Scarlett's direct monitoring with headphones if available.
Use 48 kHz for the recording workflow. Tune compression/noise reduction only
after the raw signal is clean.

For editing, switch OBS Output to Advanced and explicitly route tracks in
Advanced Audio Properties: track 1 full mix, track 2 microphone, track 3 desktop.
Enable all three recording tracks. Players commonly play only one track, so
listen to each track in the editor. Make a clap test to check camera/audio sync;
measure before entering an OBS sync offset. Exact device setup awaits hardware.

## Blender workflow and MCP

Start Blender with File → New → Video Editing. Match 1920×1080 and 30 fps
before importing footage; keep camera audio and screen clips aligned. First
milestone: import a one-minute OBS recording, trim it, add a title, and export
H.264/AAC MP4. Play the entire test and check text, audio balance, and sync.

OBS's composed recording has the webcam placement and chroma key baked in.
If moving yourself around or refining the key afterward matters, retain a
separate camera recording with its green background. Decide this before a long
session; ordinary OBS scenes alone don't produce independent video tracks.

The [ahujasid Blender MCP](https://github.com/ahujasid/blender-mcp) primarily
targets 3D work and exposes Python execution. That makes VSE automation plausible,
but it isn't a polished video-editing interface by itself. Useful first tasks:
import clips, arrange a rough cut, add title cards, set export settings. Creative
pacing, bad takes, and key quality still need playback and judgment.

MCP is not installed or connected by this setup. Choose and test it against the
native Blender installation after the capture/import/export loop works. Keep
the local bridge local and disable optional telemetry if you don't want it.

## Verification status

Demo recorder: `python3 scripts/tests/test-demo-record.py` exercises cancellation,
window selection, scoped stopping, stale PID protection, persistent follow toggles,
tracker failure, and original preservation with mock capture tools. Real FFmpeg
exports verify the moving crop and pointer composition with delayed audio, silent
portrait video, odd dimensions, and safe re-export failure. Camera checks cover
rapid toggles, capture edges, monitor offsets, and fractional scaling.

A separate headless Sway session passed a real private-recorder capture at scale
1.5, with a virtual pointer moving across a test terminal. Pointer telemetry,
follow lasting more than three seconds, and the second toggle's zoom-out were
verified; normal and moving-zoom export frames were visually checked. Continuous
capture (`-D`) prevents a still screen from stalling the video clock. This test
does not record the user's desktop.

Screenshot script: ShellCheck plus `sh scripts/tests/test-screenshot.sh` covers
cancel, capture failure, copy, annotation dispatch, and invalid arguments using
mock tools. No actual screenshot/camera recording was made by the setup agent.
Sway config validation passed with a headless backend, and all four shortcut
bindings were accepted by the running Sway session. The monitor mode was not
changed during setup.

This agent's sandbox cannot start Flatpak (`ldconfig` read-only failure), and has
no `/dev/dri` or `/dev/video*` access. OBS profile import, NVENC, the portal picker,
camera modes, and a Blender media round trip therefore still need an interactive
test. The unplugged Scarlett cannot be configured or checked yet.
