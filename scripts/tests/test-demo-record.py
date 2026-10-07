#!/usr/bin/env python3
"""Run with python3 scripts/tests/test-demo-record.py; uses real FFmpeg, mock capture."""
import hashlib
import importlib.machinery
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import types

SCRIPT = Path(__file__).resolve().parents[1] / "demo-record"
demo = types.ModuleType("demo_record")
importlib.machinery.SourceFileLoader("demo_record", str(SCRIPT)).exec_module(demo)


def wait_for(predicate):
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for recording state")


with tempfile.TemporaryDirectory(prefix="demo-record-test-") as temporary:
    root = Path(temporary)
    binaries = root / "bin"
    binaries.mkdir()
    source = root / "fixture.mkv"
    subprocess.run([
        "ffmpeg", "-v", "error", "-f", "lavfi", "-i", "testsrc2=size=640x360:rate=30",
        "-itsoffset", "0.35", "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=48000", "-t", "8",
        "-c:v", "libx264", "-preset", "ultrafast", "-c:a", "pcm_s16le", str(source)
    ], check=True)
    mock = binaries / "mock"
    mock.write_text('''#!/usr/bin/env python3
import json, os, pathlib, shutil, signal, sys, time
name = pathlib.Path(sys.argv[0]).name
if name == "slurp":
    if os.environ.get("CANCEL"): sys.exit(1)
    print(os.environ.get("AREA", "0,0 640x360"))
elif name == "swaymsg":
    rect = {"x": 0, "y": 0, "width": 640, "height": 360}
    if sys.argv[-1] == "get_outputs":
        print(json.dumps([{"name": "TEST", "active": True, "rect": rect}]))
    else:
        print(json.dumps({"nodes": [{"focused": True, "app_id": "test", "rect": rect}]}))
elif name == "wf-recorder":
    if os.environ.get("FAIL_CAPTURE"): sys.exit(2)
    print("demo-record-start", time.monotonic(), file=sys.stderr, flush=True)
    destination = sys.argv[sys.argv.index("-f") + 1]
    pathlib.Path(destination + ".args").write_text(json.dumps(sys.argv))
    shutil.copyfile(os.environ["FIXTURE"], destination)
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    while True: time.sleep(0.05)
elif name == "cc":
    shutil.copyfile(__file__, sys.argv[sys.argv.index("-o") + 1])
    pathlib.Path(sys.argv[sys.argv.index("-o") + 1]).chmod(0o755)
elif name == "demo-cursor":
    if os.environ.get("FAIL_CURSOR"): sys.exit(1)
    print('{"ready":true}', flush=True)
    start = time.monotonic()
    while True:
        now = time.monotonic()
        print(json.dumps({"time": now, "x": int((now-start)*100) % 640, "y": 180}), flush=True)
        if os.environ.get("CURSOR_DIES") and now-start > 4: sys.exit(1)
        time.sleep(0.03)
''')
    mock.chmod(0o755)
    for name in ("slurp", "swaymsg", "wf-recorder", "notify-send", "cc"):
        (binaries / name).symlink_to(mock)
    env = dict(os.environ, PATH=f"{binaries}:{os.environ['PATH']}",
               XDG_RUNTIME_DIR=str(root / "runtime"), DEMO_RECORD_DIR=str(root / "demos"),
               XDG_CACHE_HOME=str(root / "cache"),
               FIXTURE=str(source))
    state_file = root / "runtime/demo-record/state.json"
    (root / "cache/demo-record").mkdir(parents=True)
    (root / "cache/demo-record/wf-recorder").symlink_to(mock)

    def run(*args, check=True, **extra):
        return subprocess.run([str(SCRIPT), *args], env=dict(env, **extra),
                              capture_output=True, text=True, check=check)

    def state():
        try:
            return json.loads(state_file.read_text())
        except FileNotFoundError:
            return {}

    assert json.loads(run("status").stdout)["text"] == ""
    run("toggle", CANCEL="1")
    assert not (root / "demos").exists()
    assert run("toggle", check=False, AREA="600,0 100x100").returncode != 0
    assert run("zoom", check=False).returncode != 0
    assert run("stop", check=False).returncode != 0

    # This process must survive stopping our recorder, including a stale-PID check.
    unrelated = subprocess.Popen(["sleep", "60"])
    try:
        demo.stop_process([unrelated.pid, "not-the-process-start-time"])
        assert unrelated.poll() is None
        capture = subprocess.Popen([str(SCRIPT), "toggle", "--window", "--audio", "test.monitor"],
                                   env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            wait_for(lambda: state().get("phase") == "recording")
            project = Path(state()["project"])
            wait_for(lambda: (project / "raw.mkv").exists())
            assert run("render", str(project), check=False).returncode != 0
            run("zoom")
            time.sleep(3.2)
            assert "FOLLOW ON" in json.loads(run("status").stdout)["text"]
            run("zoom")
            assert "FOLLOW OFF" in json.loads(run("status").stdout)["text"]
            run("zoom")
            assert len(json.loads((project / "project.json").read_text())["zoom_toggles"]) == 3
            run("toggle")
            stdout, stderr = capture.communicate(timeout=60)
            assert capture.returncode == 0, stderr
            assert unrelated.poll() is None
        finally:
            if capture.poll() is None:
                if state().get("recorder"):
                    demo.stop_process(state()["recorder"])
                capture.kill()
                capture.wait()
        assert not state_file.exists()
        args = json.loads((project / "raw.mkv.args").read_text())
        assert "-D" in args and "--audio=test.monitor" in args and args[args.index("-o") + 1] == "TEST"
        assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256((project / "raw.mkv").read_bytes()).digest()
        info = demo.video_info(project / "demo.mp4")
        video = next(s for s in info["streams"] if s["codec_type"] == "video")
        assert (video["width"], video["height"], video["pix_fmt"]) == (1920, 1080, "yuv420p")
        audio = next(s for s in info["streams"] if s["codec_type"] == "audio")
        assert abs(float(audio["start_time"]) - 0.35) < 0.04, audio["start_time"]
        assert abs(float(info["format"]["duration"]) - 8) < 0.15
        previous_export = (project / "demo.mp4").read_bytes()
        metadata = json.loads((project / "project.json").read_text())
        metadata["zoom_toggles"] = [-1]
        (project / "project.json").write_text(json.dumps(metadata))
        assert run("render", str(project), check=False).returncode != 0
        assert (project / "demo.mp4").read_bytes() == previous_export
        assert not (project / "demo.partial.mp4").exists()

        # Silent footage, odd dimensions, no markers, and portrait aspect ratio.
        silent = root / "silent"
        silent.mkdir()
        subprocess.run(["ffmpeg", "-v", "error", "-f", "lavfi", "-i",
                        "testsrc=size=321x481:rate=30", "-t", "0.5", "-c:v", "ffv1",
                        str(silent / "raw.mkv")], check=True)
        (silent / "project.json").write_text(json.dumps({"fps": 30, "markers": []}))
        run("render", str(silent))
        assert len(demo.video_info(silent / "demo.mp4")["streams"]) == 1
        assert run("toggle", check=False, FAIL_CAPTURE="1").returncode != 0
        assert not state_file.exists()
        assert run("toggle", check=False, FAIL_CURSOR="1").returncode != 0
        assert not state_file.exists()
        assert run("toggle", check=False, CURSOR_DIES="1").returncode != 0
        assert not state_file.exists()
        assert json.loads(run("status").stdout)["text"] == ""
    finally:
        unrelated.terminate()
        unrelated.wait()

# Pointer moves across both capture edges; zoom stays on past three seconds,
# switches off, and can be toggled during its transition without a jump.
points = [(0, .1, .2), (2, .9, .8), (4, 1, 1), (5, 0, 0)]
frames = list(demo.camera_frames([.2, 6], points, 8, 640, 360, 30))
assert frames[4*30][1] < 640 and frames[5*30][1] < 640
assert frames[7*30][1:5] == (640, 360, 0, 0)
assert frames[3*30][3] > frames[1*30][3]
assert all(0 <= x <= 640-w and 0 <= y <= 360-h for _, w, h, x, y in frames)
rapid = list(demo.camera_frames([0, .1, .15, .2], points, 1, 640, 360, 60))
assert max(abs(a[1]-b[1]) for a, b in zip(rapid, rapid[1:])) < 25

# A region on a monitor left of the origin, with fractional scaling. Leaving
# hides the pointer without panning the camera toward another monitor.
with tempfile.TemporaryDirectory() as folder:
    project = Path(folder)
    metadata = {"geometry": "-1200,100 640x360", "output_rect": {"x": -1280, "y": 0},
                "output_scale": 1.5, "started": 10}
    (project / "cursor.jsonl").write_text('\n'.join(json.dumps(event) for event in [
        {"time": 10, "x": 600, "y": 420}, {"time": 11, "leave": True},
        {"time": 12, "x": 1080, "y": 690}]) + '\n')
    mapped = demo.cursor_points(project, metadata)
    assert mapped == [(0, .5, .5), (1, None, None), (2, 1, 1)], mapped
    assert list(demo.camera_frames([0], mapped, 4, 640, 360, 30))[-1][3:] == (213, 120)
print("Demo recording checks passed (mouse follow, toggle duration, audio, originals, tracker failure)")
