# dotfiles

GNU Stow–managed configs for Linux (CachyOS/Arch), macOS, and Android (Termux).

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` detects the platform and runs the matching setup script. On an
already-provisioned machine, `./bootstrap.sh --stow-only` just re-links configs.
`--dry-run` prints what would happen without touching anything.

## Layout

Each top-level directory is a stow package. `common` is always stowed, plus
exactly one platform package — so a file's path inside the package is the path
it lands on under `$HOME`.

| Package  | Stowed on | Holds |
|----------|-----------|-------|
| `common` | every machine | fish, neovim, tmux, kitty, git |
| `linux`  | Linux desktop | i3, polybar, X11, Linux-only ssh hosts, AUR packages |
| `macos`  | macOS | AeroSpace, skhd, borders, wezterm, Raycast scripts |
| `android`| Termux | Termux-specific env and widget scripts |
| `scripts`| not stowed | setup + utility scripts (on `PATH` via `config.fish`) |

## Platform-specific config

Anything platform-specific belongs in that platform's package, **not** in a
`uname` branch inside `common`. Each package drops one file into
`~/.config/fish/conf.d/`, which fish auto-sources:

- `linux/.config/fish/conf.d/linux-env.fish`
- `macos/.config/fish/conf.d/macos-env.fish`
- `android/.config/fish/conf.d/android-env.fish`

Only one is ever present on a given machine, and each self-guards anyway
(Termux reports `uname -s` as `Linux`, so the Linux/Android split keys off
`$PREFIX` instead).

### PATH additions must use `fish_add_path -g`

Bare `fish_add_path` writes to the **universal** `$fish_user_paths`, which fish
persists into `fish_variables` — a tracked file. That silently carried macOS
paths (`/opt/homebrew`, `/Applications/…`) into the repo and onto Linux boxes.
The `-g` flag keeps entries global (rebuilt each shell start) instead.

## Secrets

SSH private keys are committed as GPG-encrypted `*.gpg` files.
`scripts/stow_dotfiles.sh` decrypts them into place (mode 600) and
`.stow-local-ignore` keeps the `.gpg` originals from being symlinked.
Adding one: `scripts/add_dotfile_encrypted.sh <file> [--os linux|macos]`.

No plaintext secrets belong in this repo.

## Generated files are not tracked

- **fisher plugins** — `~/.config/fish/{functions,completions,conf.d}` are stow
  symlinks into this repo, so `fisher install` writes plugin code straight into
  the working tree. `common/.config/fish/fish_plugins` is the source of truth;
  `fisher update` restores the rest. The installed files are gitignored by
  explicit path, since hand-written functions share those directories.
- **makepkg output** — `linux/custom-aur-packages/*/{src,pkg}/` and built
  `*.pkg.tar.*`. Only `PKGBUILD` and the hand-written sources beside it.

## Neovim + treesitter

Neovim 0.12 provides treesitter in core; `nvim-treesitter` only installs parsers
and ships queries. It does **not** enable highlighting — `base_plugins.lua` calls
`vim.treesitter.start()` from a `FileType` autocmd and sets `foldexpr`/`indentexpr`
itself, which is the documented setup.

Upstream `nvim-treesitter` was archived 2026-04-03; the pin in `lazy-lock.json`
is its final commit. It works, but there will be no further parser or query
updates — see `neovim-treesitter/nvim-treesitter` if that becomes a problem.

Parsers install at `:Lazy build nvim-treesitter` time, not on every startup. To
add a language, extend `ensure` in `base_plugins.lua` and re-run the build.

## Per-platform notes

- [SETUP-MAC-INSTRUCTIONS.md](SETUP-MAC-INSTRUCTIONS.md) — AeroSpace/skhd i3-like
  setup, and the Accessibility permissions it needs
- [ANDROID-SETUP.md](ANDROID-SETUP.md) — Termux as a thin client over
  Tailscale + mosh + tmux
