fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin
s
if status is-interactive
	alias gg="ghq get"
	alias cl=clear
	alias cfg=~/.config
	alias zed=zeditor
	alias ff=fastfetch

	# ls
	if type -q eza
		alias ll "eza -l -g --icons --header --time-style=default"
		alias lla "ll -a"
		alias llt "ll --tree"
		alias llat "ll -a --tree"
	end

	# Unix convert
	alias unix=dos2unix
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
