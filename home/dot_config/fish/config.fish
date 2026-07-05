fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin

if status is-interactive
    alias gg="ghq get"
    alias cl=clear
    alias cfg=~/.config
    alias zed=zeditor
    alias ff=fastfetch
    alias rf=refresh

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

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Machine-local secrets (npm registry tokens, work-only env vars, etc.) live in
# a file that is NOT tracked by git or managed by chezmoi. Create it per machine:
#   ~/.config/fish/local.fish   e.g.  set -gx NPM_TOKEN_XXX "..."
test -f $HOME/.config/fish/local.fish && source $HOME/.config/fish/local.fish
