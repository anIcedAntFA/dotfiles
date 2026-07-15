fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin

if status is-interactive
    alias gg="ghq get"
    alias cl=clear
    alias cfg=~/.config
    alias zed=zeditor
    alias ff=fastfetch
    alias rf=refresh
    alias pw=gopass

    # ls
    if type -q eza
        alias ll "eza -l -g --icons --header --time-style=default"
        alias lla "ll -a"
        alias llt "ll --tree"
        alias llat "ll -a --tree"
    end

    # Unix convert
    alias unix=dos2unix

    auto-sync-theme

    alias ports 'ss -tlnp'

    function kport
        fuser -k "$argv[1]/tcp"
    end
end

# Starship
set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
starship init fish | source

# Mise
mise activate fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Go
set -gx GOPATH $HOME/go

# direnv
direnv hook fish | source

# zoxide — frecency directory jumper; replaces jethrokuan/z. Adds `z` (jump) and
# `zi` (fuzzy pick via fzf), leaving the builtin `cd` intact. One-time migration
# from the old z history: see docs/zoxide.md.
if type -q zoxide
    zoxide init fish | source
end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# CLI hygiene: silence gh's "new release" nags; opt out of telemetry.
# DO_NOT_TRACK is a cross-tool standard (gh and many other CLIs honor it).
set -gx GH_NO_UPDATE_NOTIFIER 1
set -gx DO_NOT_TRACK 1

# ripgrep reads no XDG path on its own — point it at the tracked config.
set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config

# gpg-agent's pinentry-curses draws in the current terminal; it needs GPG_TTY.
set -gx GPG_TTY (tty)

# Machine-local secrets (npm registry tokens, work-only env vars, etc.) live in
# a file that is NOT tracked by git or managed by chezmoi. Create it per machine:
#   ~/.config/fish/local.fish   e.g.  set -gx NPM_TOKEN_XXX "..."
test -f $HOME/.config/fish/local.fish && source $HOME/.config/fish/local.fish
