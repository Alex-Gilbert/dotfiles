// Firefox prefs that should follow the repo, not the machine.
//
// user.js is re-applied over prefs.js on every startup, so anything listed
// here is frozen — toggling it in the UI reverts on next launch. Keep this to
// prefs you'd never reach for in Settings; leave taste (theme, toolbar) to the
// UI, where Firefox Sync carries it.
//
// Not used from here: Firefox names its profile dirs randomly, so
// scripts/firefox-link-prefs.sh links this file into every profile.

// The OS owns the default-browser question. Stop the startup nag.
user_pref("browser.shell.checkDefaultBrowser", false);

// Start normally instead of reopening every window from the previous session.
user_pref("browser.startup.page", 1);

// Load restored tabs lazily when a session is restored manually.
user_pref("browser.sessionstore.restore_on_demand", true);

// Container tabs (work / personal Gmail side by side). The Multi-Account
// Containers add-on is the UI; this keeps the feature on underneath it.
user_pref("privacy.userContext.enabled", true);
user_pref("privacy.userContext.ui.enabled", true);

// Linux: use the xdg-desktop-portal file picker rather than the bundled GTK
// one, so file dialogs match the rest of the session. Ignored on macOS.
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// Hardware video decode. Default-on for Linux builds, but both hosts are
// amdgpu and this is the pref that regresses silently when it isn't.
user_pref("media.ffmpeg.vaapi.enabled", true);

// Telemetry, pinned off.
user_pref("toolkit.telemetry.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);

// This repo is where prefs get edited. Skip the "here be dragons" interstitial.
user_pref("browser.aboutConfig.showWarning", false);
