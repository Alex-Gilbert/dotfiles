# Linux desktop env. Skipped on Termux (uname -s also returns "Linux" there).
if set -q PREFIX; and test "$PREFIX" = /data/data/com.termux/files/usr
    exit
end

for dir in \
    $HOME/binaryen-version_123/bin \
    $HOME/.npm-global/bin \
    $HOME/rga-2.11.0.28 \
    $HOME/.local/CPLEX_Studio221/cplex/bin/x86-64_linux \
    $HOME/.local/zig-0.12.0 \
    $HOME/.local/pandoc-3.1.8/bin \
    $HOME/.local/renderdoc_1.31/bin \
    $HOME/dc-repos/artiv-deployment \
    $HOME/.dotnet/tools \
    $HOME/.local/azure-functions \
    $HOME/dev/defcon/skyshark/target/release
    if not contains $dir $PATH
        set -gx PATH $PATH $dir
    end
end

# `go env GOBIN` is empty when unset, and an empty string in a fish PATH list
# resolves to '.' (CWD) — shadowing installed binaries with stale local builds.
# GOPATH/bin is where `go install` writes when GOBIN is unset, so it's enough.
if command -q go
    set -l gobin (go env GOPATH)/bin
    if not contains $gobin $PATH
        set -gx PATH $PATH $gobin
    end
end

set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
