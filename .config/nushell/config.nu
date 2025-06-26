source prompt.nu
source aliases.nu

$env.config = {
    show_banner: false
    use_ansi_coloring: true
    use_kitty_protocol: true
    buffer_editor: "nvim"
    edit_mode: "vi"
    render_right_prompt_on_last_line: true
    ls: {
        use_ls_colors: true
        clickable_links: true
    }
    rm: {
        always_trash: false
    }
    cursor_shape: {
        vi_insert: "blink_line"
        vi_normal: "block"
    }
    history: {
        max_size: 1_000_000
        file_format: "sqlite"
        isolation: true
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
            enable: true
            max_results: 100
            completer: null
        }
    }
    hooks: {
        pre_prompt: [{
            code: "$env.PROMPT_INDICATOR = { $'(ansi green)❯(ansi reset) ' }"
        }]
        pre_execution: [{
            code: "$env.PROMPT_INDICATOR = { $'(ansi green)❯(ansi reset) ' }"
        }]
    }
}

# FZF integration for history search (similar to history-substring-search)
def fzf-history [] {
  history | 
  get command | 
  str trim | 
  uniq | 
  reverse | 
  str join (char -i 0) | 
  fzf --read0 | 
  str trim |
  each { |cmd| nu -c $cmd }
}



# keybindings
$env.config.keybindings ++= [
  {
    name: fzf_history
    modifier: alt
    keycode: char_r
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "fzf-history"
    }
  },
  {
    name: proj
    modifier: alt
    keycode: char_p
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "proj"
    }
  }
]


source ~/.zoxide.nu
