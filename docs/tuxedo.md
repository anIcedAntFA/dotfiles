# tuxedo — todo.txt task TUI

## Why

[tuxedo](https://github.com/webstonehq/tuxedo) is a fast, keyboard-driven terminal
UI for the [todo.txt](https://github.com/todotxt/todo.txt) format: one plain-text
file, one task per line, priorities/`+projects`/`@contexts` inline. No database, no
account — the task list is a file you can grep, sync, or edit anywhere. The package
is on the AUR (tracked in [packages.md](packages.md)).

> [!NOTE]
> This is **not** TUXEDO Computers' laptop control centre — same word, unrelated
> tool. This one only touches a text file.

## The file

By default `tuxedo` opens `./todo.txt` in the current directory, or a throwaway
sample in `/tmp` if none exists. For a single personal list, keep one at `~/todo.txt`:

```sh
tuxedo ~/todo.txt      # launch the TUI on your list
```

## Using it

Launch with no command for the interactive TUI; task numbers are 1-based line
numbers as shown by `list`. It also works one-shot from the shell:

```sh
tuxedo add "call the bank @errands +admin due:friday"   # natural-language dates
tuxedo ls +admin              # filter by project / @context / text
tuxedo pri 3 A                # set priority A on task 3
tuxedo do 3                   # complete task 3
tuxedo archive                # move done tasks to done.txt
tuxedo lsprj                  # list +projects   (lsc lists @contexts)
```

Inside the TUI, press `s` to expose a phone-friendly capture endpoint on your LAN
and show a QR code — captures land in a sibling `inbox.txt` that the TUI merges on
the next poll. Handy for jotting a task from your phone.

## niri integration

A keybind opens tuxedo in a **floating** ghostty window (so it doesn't tile over
your work) using a custom app-id that a window rule matches — both live in
[`config.kdl`](../home/dot_config/niri/config.kdl.tmpl):

```kdl
Mod+Shift+T { spawn-sh "ghostty --class=com.tuxedo.todo -e tuxedo ~/todo.txt"; }

window-rule {
  match app-id="com.tuxedo.todo"
  open-floating true
  default-column-width { fixed 1000; }
  default-window-height { fixed 700; }
}
```

`--class` sets the Wayland app-id so niri can single out this terminal; `-e` runs
tuxedo inside it. Press **Mod+Shift+T** to pop the list, `q` to dismiss.

> [!NOTE]
> After editing the KDL, run `just validate-niri` (needs niri installed) before
> committing — this repo doesn't format or auto-check KDL.

## References

- [tuxedo](https://github.com/webstonehq/tuxedo)
- [todo.txt format](https://github.com/todotxt/todo.txt)
