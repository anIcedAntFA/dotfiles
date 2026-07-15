function zj --description 'Pick/resume a zellij session or open a project layout (fzf)'
    type -q zellij; or begin
        echo 'zj: zellij is not installed' >&2
        return 1
    end

    set -l layouts_dir $HOME/.config/zellij/layouts

    # Running sessions come first (resume), then available layouts (fresh start).
    set -l menu
    for s in (zellij list-sessions --short 2>/dev/null)
        set -a menu "resume\t$s"
    end
    if test -d $layouts_dir
        for f in $layouts_dir/*.kdl
            set -l name (path change-extension '' (path basename $f))
            string match -q '_*' -- $name; and continue # skip _template etc.
            set -a menu "open\t$name"
        end
    end

    test (count $menu) -gt 0; or begin
        zellij # nothing saved yet — just start a plain session
        return
    end

    set -l pick (printf '%b\n' $menu \
        | fzf --delimiter \t --with-nth 1,2 --height 40% --reverse --prompt 'zellij ❯ ')
    or return

    set -l kind (string split -f1 \t -- $pick)
    set -l name (string split -f2 \t -- $pick)

    if test "$kind" = resume
        zellij attach -- $name
    else
        # One session per project, named after the layout: resume if it's
        # already running, otherwise create it from the layout.
        if zellij list-sessions --short 2>/dev/null | string match -qx -- $name
            zellij attach -- $name
        else
            zellij --session $name --layout $name
        end
    end
end
