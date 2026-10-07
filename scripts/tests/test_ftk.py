"""Run with python3 scripts/tests/test_ftk.py; only uses disposable tmux servers."""
import os
from pathlib import Path
import subprocess
import tempfile

function = Path(__file__).resolve().parents[2] / "common/.config/fish/functions/ftk.fish"
with tempfile.TemporaryDirectory(prefix="ftk-", dir="/tmp") as tmp:
    env = {**os.environ, "TMUX_TMPDIR": tmp}
    env.pop("TMUX", None)
    sockets = [f"{tmp}/tmux-{os.getuid()}/{name}" for name in ("default", "other")]

    def tmux(socket, *args):
        return subprocess.run(["tmux", "-S", socket, *args], env=env,
                              capture_output=True, text=True)

    try:
        for socket in sockets:
            Path(socket).parent.mkdir(exist_ok=True, mode=0o700)
            assert tmux(socket, "-f", "/dev/null", "new-session", "-d", "-s", "same", "sleep 120").returncode == 0
        script = '''
source $argv[1]
function fzf
    if test "$FTK_CANCEL" = 1
        cat >/dev/null
        return 130
    end
    command grep /other
end
ftk
'''
        for cancel in ("1", "0"):
            result = subprocess.run(["fish", "--no-config", "-c", script, str(function)],
                                    env={**env, "FTK_CANCEL": cancel}, capture_output=True, text=True)
            assert tmux(sockets[0], "has-session", "-t", "=same").returncode == 0, "Wrong server killed"
            alive = tmux(sockets[1], "has-session", "-t", "=same").returncode == 0
            assert alive == (cancel == "1"), ("Selection/cancellation failed", result.stdout, result.stderr)
        print("PASS: cross-server selection, duplicate names, and cancellation")
    finally:
        for socket in sockets:
            tmux(socket, "kill-server")
