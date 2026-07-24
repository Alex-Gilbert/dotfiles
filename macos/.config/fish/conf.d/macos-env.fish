# macOS env. Guard so a stray stow of this package on Linux is a no-op.
if test (uname -s) != Darwin
    exit
end

# .NET via Homebrew. --move so the Homebrew libexec wins over any older
# /usr/local/share/dotnet left behind by a standalone installer.
if test -d /opt/homebrew/opt/dotnet/libexec
    set -gx DOTNET_ROOT /opt/homebrew/opt/dotnet/libexec
    fish_add_path -gm /opt/homebrew/opt/dotnet/libexec
end

# `go env GOPATH` costs ~160ms; read $GOPATH directly or use the default.
if set -q GOPATH
    fish_add_path -g $GOPATH/bin
else
    fish_add_path -g $HOME/go/bin
end

# VS Code CLI (`code`) on PATH.
set -l _vscode_bin "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if test -d $_vscode_bin
    fish_add_path -g $_vscode_bin
end
