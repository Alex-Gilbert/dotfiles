# Vault sync on archbtw

Neovim and agents edit `/home/alex/alex-vault`. The `livesync-archbtw`
user service watches the filesystem and synchronises with CouchDB on mini.
Obsidian does not need to run here. Its LiveSync plug-in is disabled on
archbtw to leave synchronisation to the daemon.

## Installed configuration

- Server: `https://osync.gilbert.haus` (mini over Tailscale).
- Active database: `alex-vault-archbtw-20260909`.
- Previous database: `alex-vault`, preserved unchanged for recovery.
- Private client settings/state: `~/.local/share/livesync-archbtw/`.
- Service: `~/.local/share/systemd/user/livesync-archbtw.service`.
- CLI source/build: `~/.local/share/obsidian-recovery/livesync-source/`.
- CLI version: `1.0.28-cli`, commit `b3d01598ac044392c9c26ba3697f6bb67bcfcbcf`.
- Startup: enabled for the user default target; user lingering is enabled.

The daemon watches ordinary vault files, including attachments. Hidden
files/directories such as `.obsidian`, `.git`, and `.trash` are excluded.
The existing 50 MB per-file limit is retained; all 788 initial files fit.

## Operate

```sh
systemctl --user status livesync-archbtw
journalctl --user-unit=livesync-archbtw -n 50
systemctl --user restart livesync-archbtw
systemctl --user stop livesync-archbtw
```

From a sandbox where the ordinary user bus is unavailable, use
`systemctl --user --machine=alex@.host` instead of `systemctl --user`.

Keep the service running while editing. The CLI watches deletions while
running, but its startup mirror can restore files deleted while it was
stopped. Do not treat a stopped daemon as a safe bulk-deletion workflow.

## Reconnect other devices

Their existing configuration still targets the old database. Keep those
clients paused until reconfigured. Back up each old vault, then use a new,
empty vault with an up-to-date Self-hosted LiveSync plug-in and fetch the
new database. Do not upload an old device's vault into the new database.

A verified, encrypted setup URI and its separate unlock password are in:

- `~/.local/share/obsidian-recovery/new-device-setup-uri.txt`
- `~/.local/share/obsidian-recovery/new-device-setup-password.txt`

Both files are private (0600). The setup URI carries credentials; keep it
out of git and shared notes. The unlock password is for the setup URI,
not the vault encryption key. Existing vault encryption was retained.

## Recovery and checks

Full vault archives from before the change are in
`~/.local/share/obsidian-recovery/`. Original private LiveSync settings
are preserved there as `original-settings.json`.

On 2026-09-09, an independent download from mini matched the SHA-256 hashes
of all 788 visible vault files. The original local files were unchanged.
Evidence: `verification.json` and `vault-before-sync.sha256.json` in that
recovery directory.

The runnable check below uses a temporary remote database and temporary
vaults; it tests create, atomic save, incoming edit, rename, and delete,
then removes its temporary database:

```sh
python ~/.local/share/obsidian-recovery/check-sync.py
```

Upstream documentation:
https://github.com/vrtmrz/obsidian-livesync/blob/main/src/apps/cli/README.md
