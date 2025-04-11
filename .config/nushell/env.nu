# Environment variables
$env.PATH = (
  $env.PATH | 
  append [
    $"($env.HOME)/rga-2.11.0.28"
    $"($env.HOME)/.local/CPLEX_Studio221/cplex/bin/x86-64_linux"
    $"($env.HOME)/.local/zig-0.12.0"
    $"($env.HOME)/.local/pandoc-3.1.8/bin"
    $"($env.HOME)/.local/renderdoc_1.31/bin"
    $"($env.HOME)/dotfiles/scripts"
    $"($env.HOME)/dc-repos/artiv-deployment"
    $"($env.HOME)/.local/bin"
    $"($env.HOME)/.dotnet/tools"
    $"($env.HOME)/.local/azure-functions"
    $"($env.HOME)/dev/defcon/skyshark/target/release"
  ]
)

# Other environment variables
$env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"
$env.GAMS_VERSION = "46.4"

# Add LS_COLORS to preserve colored ls output
$env.LS_COLORS = (if 'LS_COLORS' in $env { $env.LS_COLORS } else { "" })

zoxide init nushell --cmd cd | save -f ~/.zoxide.nu
