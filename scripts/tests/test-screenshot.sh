#!/bin/sh
# Exercise cancellation, capture failure, copying, and annotation without a display.
set -eu
script=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)/screenshot
CAPTURE_TEST_DIR=$(mktemp -d)
export CAPTURE_TEST_DIR
trap 'rm -rf "$CAPTURE_TEST_DIR"' EXIT
# Check the real destination, then redirect only the test copy into temporary storage.
# shellcheck disable=SC2016
test "$(sed -n '/^directory=/p' "$script")" = 'directory="$HOME/Pictures/screenshots"'
# shellcheck disable=SC2016
sed 's|directory="$HOME/Pictures/screenshots"|directory="$CAPTURE_TEST_DIR/Pictures/screenshots"|' "$script" > "$CAPTURE_TEST_DIR/screenshot"
script="$CAPTURE_TEST_DIR/screenshot"
chmod +x "$script"
mkdir "$CAPTURE_TEST_DIR/bin"
cat > "$CAPTURE_TEST_DIR/bin/mock" <<'SH'
#!/bin/sh
case "${0##*/}" in
    slurp) [ "${CANCEL:-0}" = 0 ] || exit 1; echo '0,0 100x100' ;;
    grim) [ "${FAIL_CAPTURE:-0}" = 0 ] || exit 1; echo png > "$3" ;;
    wl-copy) cat > "$CAPTURE_TEST_DIR/clipboard" ;;
    pinta) test "$#" = 1 && test -s "$1" || exit 1; printf '%s\n' "$1" > "$CAPTURE_TEST_DIR/annotation" ;;
    notify-send) : ;;
esac
SH
chmod +x "$CAPTURE_TEST_DIR/bin/mock"
for command in slurp grim wl-copy pinta notify-send; do
    ln -s mock "$CAPTURE_TEST_DIR/bin/$command"
done
export PATH="$CAPTURE_TEST_DIR/bin:$PATH"
CANCEL=1 "$script"
test ! -e "$CAPTURE_TEST_DIR/Pictures"
if FAIL_CAPTURE=1 "$script"; then exit 1; fi
test -z "$(ls -A "$CAPTURE_TEST_DIR/Pictures/screenshots")"
"$script" copy
test "$(cat "$CAPTURE_TEST_DIR/clipboard")" = png
"$script" annotate
test -s "$CAPTURE_TEST_DIR/annotation"
if "$script" invalid; then exit 1; fi
echo 'Screenshot checks passed'
