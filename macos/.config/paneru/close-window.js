// Close the focused window for Paneru's Hyper-q.
// argv[0] is the bundle id of the app Paneru has focused; anything else in front is
// not what the user is looking at, so leave it alone.
// Press its close button; windows without a title bar (kitty) have none, so
// fall back to cmd-w once Hyper is released (else it would arrive as Hyper-w).
ObjC.import('AppKit');

function run(argv) {
  const se = Application('System Events');
  const front = se.processes.whose({ frontmost: true })[0];
  if (front.bundleIdentifier() !== argv[0]) {
    console.log(`not closing: ${front.bundleIdentifier()} is in front, expected ${argv[0]}`);
    return;
  }

  const win = front.windows[0];
  const close = win.buttons.whose({ subrole: 'AXCloseButton' });

  if (close.length > 0) {
    close[0].click();
  } else {
    const MODS = 0x1e0000; // shift | ctrl | alt | cmd
    for (let i = 0; i < 100 && ($.NSEvent.modifierFlags & MODS); i++) delay(0.02);
    se.keystroke('w', { using: 'command down' });
  }
}
