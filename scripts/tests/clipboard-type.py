import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

script = Path(__file__).resolve().parent.parent / 'clipboard-type'


def wait_for(predicate):
    deadline = time.monotonic() + 3
    while not predicate():
        assert time.monotonic() < deadline, 'timed out'
        time.sleep(0.01)


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / 'evdev.py').write_text('''
import os
from types import SimpleNamespace

ecodes = SimpleNamespace(EV_KEY=1, KEY_A=30, KEY={30: 'KEY_A'})
def list_devices():
    return [] if os.environ.get('NO_KEYBOARD') else [os.environ['KEYBOARD']]
class InputDevice:
    def __init__(self, path):
        self.fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)
    def fileno(self): return self.fd
    def capabilities(self): return {1: [30]}
    def close(self): os.close(self.fd)
    def active_keys(self): return []
    def read(self):
        return [SimpleNamespace(type=1, code=30, value=value) for value in os.read(self.fd, 1024)]
''')
    stub = '''#!/usr/bin/python3
import json, os, pathlib, signal, sys, time
name = pathlib.Path(sys.argv[0]).name
if name in ('wl-paste', 'xclip'):
    sys.stdout.write(os.environ['TEXT'])
    sys.exit(int(os.environ['FAIL']))
elif name != 'notify-send':
    result = pathlib.Path(os.environ['RESULT'])
    result.write_text(json.dumps([name, sys.argv[1:], sys.stdin.read()]))
    if os.environ.get('HOLD'):
        def stopped(*_):
            result.with_suffix('.stopped').touch()
            sys.exit(0)
        signal.signal(signal.SIGTERM, stopped)
        result.with_suffix('.ready').touch()
        time.sleep(10)
'''
    for name in ('wl-paste', 'xclip', 'wtype', 'xdotool', 'notify-send'):
        (root / name).write_text(stub)
        (root / name).chmod(0o700)
    keyboard = root / 'keyboard'
    os.mkfifo(keyboard)
    result_file = root / 'result'
    environment = os.environ | {
        'PATH': f'{root}:/usr/bin', 'RESULT': str(result_file),
        'PYTHONPATH': directory, 'XDG_CACHE_HOME': directory,
        'KEYBOARD': str(keyboard), 'TEXT': 'hello', 'FAIL': '0',
    }
    for wayland in ('wayland-1', ''):
        env = environment | {'WAYLAND_DISPLAY': wayland}
        for contents, fail in [("--hello 'world' $HOME `literal` café\n\tline two\n\n", '0'), ('', '0'), ('partial', '1')]:
            result_file.unlink(missing_ok=True)
            result = subprocess.run([str(script)], env=env | {'TEXT': contents, 'FAIL': fail}, capture_output=True, timeout=3)
            assert result.returncode == int(fail), result.stderr
            assert result_file.exists() == bool(contents and fail == '0')
            if result_file.exists():
                name, args, typed = json.loads(result_file.read_text())
                assert typed == contents
                assert name == ('wtype' if wayland else 'xdotool')
                assert args == (['-d', '34', '-'] if wayland else ['type', '--clearmodifiers', '--delay', '34', '--file', '-'])

        result_file.unlink(missing_ok=True)
        for suffix in ('.ready', '.stopped'):
            result_file.with_suffix(suffix).unlink(missing_ok=True)
        process = subprocess.Popen([str(script)], env=env | {'HOLD': '1'})
        try:
            wait_for(result_file.with_suffix('.ready').exists)
            # A concurrent invocation must not start another typer.
            subprocess.run([str(script)], env=env | {'TEXT': 'wrong'}, check=True, timeout=1)
            assert json.loads(result_file.read_text())[2] == 'hello'
            with keyboard.open('wb', buffering=0) as device:
                device.write(bytes([0]))  # Releasing the launch shortcut is harmless.
                time.sleep(0.05)
                assert process.poll() is None
                device.write(bytes([1]))  # Any key down cancels the typing child.
            wait_for(result_file.with_suffix('.stopped').exists)
            subprocess.run([str(script)], env=env | {'TEXT': 'wrong'}, check=True, timeout=1)
            assert json.loads(result_file.read_text())[2] == 'hello', 'Hyper+V release restarted typing'
            assert process.wait(timeout=1) == 0
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
        # The lock is released after cancellation, so the next shortcut works.
        subprocess.run([str(script)], env=env | {'TEXT': 'restart'}, check=True, timeout=3)
        assert json.loads(result_file.read_text())[2] == 'restart'

    result_file.unlink()
    result = subprocess.run([str(script)], env=environment | {'NO_KEYBOARD': '1'}, capture_output=True, timeout=3)
    assert result.returncode == 1 and b'No readable keyboard' in result.stderr
    assert not result_file.exists(), 'must not type without a working stop mechanism'
print('PASS: both backends, exact text, empty/read failures, key cancellation, no restart, lock cleanup, inaccessible keyboard')
