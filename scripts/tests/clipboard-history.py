import os
from pathlib import Path
import subprocess
import tempfile

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    mocks = {
        'cliphist': '''#!/bin/sh
case "$1" in
list) printf '1\\tpreview\\n' ;;
decode) [ "$CASE" != decode_failure ] || exit 1; printf 'decoded content' ;;
esac
''',
        'wofi': '''#!/bin/sh
cat >/dev/null
case "$CASE" in
cancel) exit 1 ;;
empty) exit 0 ;;
*) printf '1\\tpreview\\n' ;;
esac
''',
        'wl-copy': '#!/bin/sh\ncat > "$COPIED"\n',
    }
    for name, contents in mocks.items():
        path = root / name
        path.write_text(contents)
        path.chmod(0o700)
    target = root / 'clipboard'
    environment = os.environ | {'PATH': str(root) + ':' + os.environ['PATH'], 'COPIED': str(target)}
    for case in ('cancel', 'empty', 'decode_failure', 'success'):
        target.write_text('original content')
        result = subprocess.run([str(Path(__file__).resolve().parent.parent / 'clipboard-history.sh')], env=environment | {'CASE': case})
        assert result.returncode == (1 if case == 'decode_failure' else 0), case
        assert target.read_text() == ('decoded content' if case == 'success' else 'original content'), case
print('PASS: cancellation, empty selection, decode failure preserve clipboard; success copies selection')
