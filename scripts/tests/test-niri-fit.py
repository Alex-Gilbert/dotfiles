#!/usr/bin/env python3
"""Run with python3 scripts/tests/test-niri-fit.py; uses a mock `niri msg`."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

SCRIPT = Path(__file__).resolve().parents[1] / "niri-fit"

with tempfile.TemporaryDirectory(prefix="niri-fit-test-") as temporary:
    root = Path(temporary)
    binaries = root / "bin"
    binaries.mkdir()
    calls = root / "calls"
    mock = binaries / "niri"
    # Workspace 1 is focused and holds columns 1-3 (column 2 is a two-window stack)
    # plus a floating window; workspace 2 holds one window.
    mock.write_text('''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[2:]
if args[0] == "--json":
    what = args[1]
    def win(id, ws, col, floating=False):
        return {"id": id, "workspace_id": ws, "is_floating": floating,
                "layout": {"pos_in_scrolling_layout": None if floating else [col, 1]}}
    if what == "event-stream":
        # Hyper+N on workspace 2 happens after watch has started (and reset state)
        state = os.path.expanduser("~/.local/state/niri/aligned.json")
        open(state, "w").write("[2]")
    print(json.dumps({
        "workspaces": [{"id": 1, "is_focused": True}, {"id": 2, "is_focused": False}],
        "windows": [win(10, 1, 1), win(11, 1, 2), win(12, 1, 2), win(13, 1, 3),
                    win(14, 1, 0, floating=True), win(20, 2, 1)],
        "focused-window": {"id": 11},
        "event-stream": None,
    }[what]) if what != "event-stream" else "\\n".join(json.dumps(e) for e in [
        {"WorkspaceActivated": {"id": 2, "focused": True}},
        {"WorkspaceActivated": {"id": 1, "focused": False}},
    ]))
else:
    with open(os.environ["CALLS"], "a") as f:
        f.write(" ".join(args) + "\\n")
''')
    mock.chmod(0o755)
    (binaries / "notify-send").symlink_to("/usr/bin/true" if Path("/usr/bin/true").exists() else "/bin/true")
    env = dict(os.environ, HOME=str(root), CALLS=str(calls), PATH=f"{binaries}:{os.environ['PATH']}")
    state = root / ".local/state/niri"
    center = state / "center.kdl"

    def run(command):
        subprocess.run([str(SCRIPT), command], env=env, check=True)

    def aligned():
        return json.loads((state / "aligned.json").read_text())

    # Fit: each tiled column on workspace 1 gets 1/3, then focus goes back; centering untouched
    run("fit")
    assert not center.exists()
    assert calls.read_text().splitlines() == [
        "action focus-column 1", "action set-column-width 33.3333%",
        "action focus-column 2", "action set-column-width 33.3333%",
        "action focus-column 3", "action set-column-width 33.3333%",
        "action focus-window --id 11",
    ], calls.read_text()

    # Align: centering off here, scroll flush left, focus back
    calls.unlink()
    run("align")
    assert aligned() == [1]
    assert center.read_text() == 'layout { center-focused-column "never"; }\n'
    assert calls.read_text().splitlines() == ["action focus-column-first", "action focus-window --id 11"]

    # Again: centering back on and the focused column re-centred
    calls.unlink()
    run("align")
    assert aligned() == []
    assert not center.exists()
    assert calls.read_text().splitlines() == ["action center-column"]

    # watch resets state, then follows focus: aligned workspace 2 gains focus ->
    # centering off; workspace 1 activating without focus is ignored
    (state / "aligned.json").write_text("[1]")
    center.write_text("stale")
    run("watch")
    assert aligned() == [2]
    assert center.read_text() == 'layout { center-focused-column "never"; }\n'

    # Split: Hyper+V arms on the focused window (11, column 2), again cancels
    split = state / "split"
    run("split")
    assert split.read_text() == "11"
    run("split")
    assert not split.exists()

# Split placement and watch's new-window detection, with niri stubbed in-process
import importlib.machinery, importlib.util, io
loader = importlib.machinery.SourceFileLoader("niri_fit", str(SCRIPT))
spec = importlib.util.spec_from_loader("niri_fit", loader)
fit = importlib.util.module_from_spec(spec)
loader.exec_module(fit)

with tempfile.TemporaryDirectory(prefix="niri-split-test-") as temporary:
    fit.STATE = Path(temporary)
    fit.SPLIT = fit.STATE / "split"
    fit.ALIGNED = fit.STATE / "aligned.json"
    actions = []
    fit.niri = lambda *args: actions.append(args) or ""
    fit.notify = lambda message: None

    def win(id, col, ws=1, floating=False):
        return {"id": id, "workspace_id": ws, "is_floating": floating,
                "layout": {"pos_in_scrolling_layout": None if floating else [col, 1]}}

    windows = [win(11, 2), win(12, 5)]
    fit.query = lambda what: {"windows": windows, "workspaces": [{"id": 1, "is_focused": True}]}[what]

    def opened(window, armed="11"):
        actions.clear()
        fit.SPLIT.write_text(armed)
        fit.place_split(window)
        assert not fit.SPLIT.exists()  # one-shot either way
        return actions

    assert opened(win(30, 3)) == [("action", "consume-or-expel-window-left", "--id", "30")]
    assert opened(win(30, 6)) == []                 # focus moved: not next to the armed window
    assert opened(win(30, 3, ws=2)) == []           # other workspace
    assert opened(win(30, 0, floating=True)) == []  # floating windows stay floating
    assert opened(win(30, 3), armed="99") == []     # armed window has closed

    # watch only treats unseen ids as new: a title change on 11 must not use up the split
    events = [{"WindowsChanged": {"windows": [{"id": 11}]}},
              {"WindowOpenedOrChanged": {"window": win(11, 2)}},
              {"WindowOpenedOrChanged": {"window": win(30, 3)}}]
    class Stream:
        def __init__(self, *args, **kwargs):
            fit.SPLIT.write_text("11")  # armed after watch's startup reset
            self.stdout = io.StringIO("".join(json.dumps(e) + "\n" for e in events))
    fit.subprocess.Popen = Stream
    actions.clear()
    fit.watch()
    assert actions == [("action", "consume-or-expel-window-left", "--id", "30")], actions

print("ok")
