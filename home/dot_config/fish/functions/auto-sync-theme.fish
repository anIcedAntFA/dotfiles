function auto-sync-theme
    set -l raw (dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null)

    if test -z "$raw"
        return
    end

    # remove single quotes
    set -l mode (string replace -a "'" "" -- $raw)

    if test "$mode" = prefer-dark
        if test "$__current_theme" != "Dracula Official"
            fish_config theme choose "Dracula Official"
            set -U __current_theme "Dracula Official"
        end
    else
        if test "$__current_theme" != "Catppuccin Latte"
            fish_config theme choose "Catppuccin Latte"
            set -U __current_theme "Catppuccin Latte"
        end
    end
end
