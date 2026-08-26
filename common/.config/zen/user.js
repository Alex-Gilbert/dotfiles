// Zen (Gecko) prefs that should follow the repo, not the machine.
//
// user.js is re-applied over prefs.js on every startup, so anything listed
// here is frozen — toggling it in the UI reverts on next launch. Keep this to
// prefs you'd never reach for in Settings; leave taste (theme, compact mode,
// workspaces) to the UI, where Zen's own sync carries it.
//
// Not stowed into place directly: Zen names its profile dir randomly. Link it
// once per machine — see SETUP-BROWSER.md.

// xdg-settings owns the default-browser question. Stop the startup nag.
user_pref("browser.shell.checkDefaultBrowser", false);

// Restore the previous session. Explicit because the tiling WM keybind means
// a browser gets relaunched constantly.
user_pref("browser.startup.page", 3);

// ...but restore tabs lazily, on first click. Without this, startup.page=3
// reloads every tab at launch and the cold start gets much worse.
user_pref("browser.sessionstore.restore_on_demand", true);

// Use the xdg-desktop-portal file picker rather than the bundled GTK one, so
// file dialogs match the rest of the sway session.
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// Hardware video decode. Default-on for Linux Firefox builds, but both hosts
// are amdgpu and this is the pref that regresses silently when it isn't.
user_pref("media.ffmpeg.vaapi.enabled", true);

// Telemetry. Zen already ships most of this off; pinned so it stays off.
user_pref("toolkit.telemetry.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);

// This repo is where prefs get edited. Skip the "here be dragons" interstitial.
user_pref("browser.aboutConfig.showWarning", false);

// Compact mode: don't reveal the sidebar when the pointer grazes the screen
// edge. Zen already ships a keybind for it — "zen-compact-mode-show-sidebar",
// Ctrl+Alt+S by default — so the hover trigger is pure accident surface.
// Rebind it in Settings -> Keyboard shortcuts; that lands in the profile's
// zen-keyboard-shortcuts.json, not here.
user_pref("zen.view.compact.show-sidebar-and-toolbar-on-hover", false);
