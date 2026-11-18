function prs --description 'Review pull requests of this repo in nvim (Gitea: PR buffer + inline review; GitHub: diffview)'
    nvim -c 'lua vim.schedule(require("alex-config.forge").pick)'
end
