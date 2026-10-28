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
        # Hyper+M on workspace 2 happens after watch has started (and reset state)
        state = os.path.expanduser("~/.local/state/niri/fitted.json")
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

    def fitted():
        return json.loads((state / "fitted.json").read_text())

    # Fit: each tiled column on workspace 1 gets 1/3, then focus goes back
    run("toggle")
    assert fitted() == [1]
    assert center.read_text() == 'layout { center-focused-column "never"; }\n'
    assert calls.read_text().splitlines() == [
        "action focus-column 1", "action set-column-width 33.3333%",
        "action focus-column 2", "action set-column-width 33.3333%",
        "action focus-column 3", "action set-column-width 33.3333%",
        "action focus-window --id 11",
    ], calls.read_text()

    # Toggling again unfits the workspace and brings centering back
    run("toggle")
    assert fitted() == []
    assert not center.exists()

    # watch resets state, then follows focus: fitted workspace 2 gains focus ->
    # centering off; workspace 1 activating without focus is ignored
    (state / "fitted.json").write_text("[1]")
    center.write_text("stale")
    run("watch")
    assert fitted() == [2]
    assert center.read_text() == 'layout { center-focused-column "never"; }\n'

print("ok")
