#!/usr/bin/env python3
"""Run from the host terminal to check GPU grants and filesystem isolation."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

HELPER = Path('/home/alex/dev/codex-gpu-pass-through/codex-rust-v0.161.0/codex-rs/target/debug/codex-linux-sandbox')
DEVICES = ['/dev/nvidia0', '/dev/nvidiactl', '/dev/nvidia-modeset',
           '/dev/nvidia-uvm', '/dev/nvidia-uvm-tools', '/dev/dri/renderD128']
WRITABLE = ['/home/alex/dev', '/home/alex/alex-vault', '/home/alex/dotfiles',
            '/home/alex/.cache', '/home/alex/.cargo', '/home/alex/.local/share', '/tmp']


def main():
    if not Path('/dev/nvidiactl').exists():
        raise SystemExit('Run this check in a normal desktop terminal; NVIDIA devices are hidden here.')
    if not HELPER.is_file():
        raise SystemExit(f'Missing patched sandbox helper: {HELPER}')
    def entry(path, access):
        return {'path': {'type': 'path', 'path': str(path)}, 'access': access}
    entries = [entry('/', 'read')]
    entries += [entry(p, 'write') for p in WRITABLE + DEVICES]
    entries += [entry('/home/alex/' + p, 'deny') for p in ['.aws', '.ssh', '.gnupg']]
    with tempfile.TemporaryDirectory(prefix='codex-gpu-check-') as tmp:
        fixture = Path(tmp)
        (fixture / 'denied').write_text('test fixture')
        (fixture / 'readonly').write_text('must survive unchanged')
        entries += [entry(fixture / 'denied', 'deny'), entry(fixture / 'readonly', 'read')]
        profile = {'type': 'managed', 'file_system': {'type': 'restricted', 'entries': entries},
                   'network': 'enabled'}
        code = r'''
import pathlib, subprocess, sys
p = pathlib.Path(sys.argv[1])
for name, mode in [('denied', 'r'), ('readonly', 'w')]:
    try:
        with (p / name).open(mode):
            pass
    except PermissionError:
        pass
    except OSError as e:
        if name != 'readonly' or e.errno != 30:
            raise
    else:
        raise AssertionError(name + ' restriction failed')
(p / 'allowed').write_text('write works')
status = dict(line.split(':', 1) for line in pathlib.Path('/proc/self/status').read_text().splitlines() if ':' in line)
assert status['NoNewPrivs'].strip() == '1'
assert status['Seccomp'].strip() == '2'
assert not pathlib.Path('/dev/dri/renderD129').exists(), 'ungranted GPU exposed'
subprocess.run(['/usr/bin/nvidia-smi', '-L'], check=True)
subprocess.run(['/usr/bin/vulkaninfo', '--summary'], check=True)
print('PASS: NVML, Vulkan, writable scratch, read-only/deny rules, seccomp, and GPU isolation')
'''
        env = dict(os.environ)
        for key in ['DISPLAY', 'WAYLAND_DISPLAY', 'VK_ICD_FILENAMES', 'VK_DRIVER_FILES', 'LD_LIBRARY_PATH']:
            env.pop(key, None)
        subprocess.run([str(HELPER), '--sandbox-policy-cwd', '/home/alex/dev/red-baron',
                        '--permission-profile', json.dumps(profile), '--',
                        '/usr/bin/python3', '-c', code, tmp], env=env, check=True)
        assert (fixture / 'readonly').read_text() == 'must survive unchanged'


if __name__ == '__main__':
    main()
