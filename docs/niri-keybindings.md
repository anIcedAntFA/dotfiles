# niri — keybindings reference

Every keybind in [`config.kdl.tmpl`](../home/dot_config/niri/config.kdl.tmpl),
grouped by intent. This page is the source of truth; the config keeps only short
inline comments so the two don't drift. Concepts behind the actions live in
[niri-concepts.md](niri-concepts.md).

`Mod` is the **Super** (logo) key. Press **`Mod+Shift+/`** in a session to see
the live overlay generated from your actual binds.

## The modifier logic

You only really memorise the _focus_ keys — the modifiers layer predictably on
top:

| Add this…          | …and the action becomes                                |
| ------------------ | ------------------------------------------------------ |
| `Ctrl`             | **move** the focused column/window instead of focus it |
| `Shift` (+ arrows) | act on **monitors** instead of columns                 |
| `Shift` (+ digits) | **move column to** workspace N instead of focus it     |
| `Shift+Ctrl`       | **move column to monitor** in that direction           |

Directions are literal: **Left/Right = columns** (along the strip),
**Up/Down = windows in a column / workspaces**. Arrow keys and `h j k l` are
interchangeable everywhere.

## Overview & window lifecycle

| Keybind       | Action                | What it does                       |
| ------------- | --------------------- | ---------------------------------- |
| `Mod+O`       | `toggle-overview`     | Open/close the zoomed-out overview |
| `Mod+Q`       | `close-window`        | Close the focused window           |
| `Mod+Shift+/` | `show-hotkey-overlay` | Show the important-hotkeys popup   |

## Applications & launchers

| Keybind       | Action / command          | What it does                  |
| ------------- | ------------------------- | ----------------------------- |
| `Mod+D`       | noctalia launcher toggle  | App launcher                  |
| `Mod+Shift+C` | noctalia launcher (clip)  | Clipboard history panel       |
| `Mod+T`       | `spawn ghostty`           | Open a terminal               |
| `Mod+Shift+T` | `spawn` tuxedo in ghostty | Todo.txt TUI (opens floating) |
| `Mod+B`       | `spawn waterfox`          | Open the browser              |
| `Super+Alt+L` | `spawn swaylock`          | Lock the screen               |

## Screenshots & capture

| Keybind            | Action / command                 | What it does                             |
| ------------------ | -------------------------------- | ---------------------------------------- |
| `Mod+S`            | `dot-screenshot region`          | Region → satty for annotation            |
| `Mod+Shift+S`      | `dot-screenshot window`          | Focused window → satty                   |
| `Mod+Ctrl+S`       | `dot-screenshot monitor-focused` | Focused monitor → satty                  |
| `Mod+Ctrl+Shift+S` | `dot-screenshot monitor-all`     | All monitors → satty                     |
| `Ctrl+Print`       | `screenshot-screen`              | Built-in: whole screen straight to disk  |
| `Alt+Print`        | `screenshot-window`              | Built-in: focused window to disk         |
| `Mod+Print`        | `dot-screenrec region`           | Start recording a slurp region           |
| `Mod+Shift+Print`  | `dot-screenrec screen`           | Start recording the focused monitor      |
| `Mod+Ctrl+Print`   | `dot-screenrec stop`             | Stop & save the running recording        |
| `Super+Alt+S`      | toggle `orca`                    | Screen reader on/off (works when locked) |

See [screenshot.md](screenshot.md) for how `dot-screenshot` wires grim/slurp into
satty, and [screen-recording.md](screen-recording.md) for `dot-screenrec`.

## Audio & brightness (media keys)

All work on the lock screen (`allow-when-locked`).

| Keybind                 | What it does           |
| ----------------------- | ---------------------- |
| `XF86AudioRaiseVolume`  | Volume +10%            |
| `XF86AudioLowerVolume`  | Volume −10%            |
| `XF86AudioMute`         | Mute/unmute output     |
| `XF86AudioMicMute`      | Mute/unmute microphone |
| `XF86MonBrightnessUp`   | Brightness +5%         |
| `XF86MonBrightnessDown` | Brightness −5%         |

## Focus columns & windows

| Keybind               | Action               | What it does                       |
| --------------------- | -------------------- | ---------------------------------- |
| `Mod+Left` / `Mod+H`  | `focus-column-left`  | Focus the column to the left       |
| `Mod+Right` / `Mod+L` | `focus-column-right` | Focus the column to the right      |
| `Mod+Up` / `Mod+K`    | `focus-window-up`    | Focus the window above (in column) |
| `Mod+Down` / `Mod+J`  | `focus-window-down`  | Focus the window below (in column) |
| `Mod+Home`            | `focus-column-first` | Jump to the first column           |
| `Mod+End`             | `focus-column-last`  | Jump to the last column            |

## Move columns & windows (add `Ctrl`)

| Keybind                         | Action                 | What it does                       |
| ------------------------------- | ---------------------- | ---------------------------------- |
| `Mod+Ctrl+Left` / `Mod+Ctrl+H`  | `move-column-left`     | Move column left along the strip   |
| `Mod+Ctrl+Right` / `Mod+Ctrl+L` | `move-column-right`    | Move column right                  |
| `Mod+Ctrl+Up` / `Mod+Ctrl+K`    | `move-window-up`       | Move window up within its column   |
| `Mod+Ctrl+Down` / `Mod+Ctrl+J`  | `move-window-down`     | Move window down within its column |
| `Mod+Ctrl+Home`                 | `move-column-to-first` | Move column to the start           |
| `Mod+Ctrl+End`                  | `move-column-to-last`  | Move column to the end             |

## Monitors (`Shift` = focus, `Shift+Ctrl` = move column)

| Keybind                           | Action                         | What it does                     |
| --------------------------------- | ------------------------------ | -------------------------------- |
| `Mod+Shift+Left` / `Mod+Shift+H`  | `focus-monitor-left`           | Focus the monitor to the left    |
| `Mod+Shift+Right` / `Mod+Shift+L` | `focus-monitor-right`          | Focus the monitor to the right   |
| `Mod+Shift+Up` / `Mod+Shift+K`    | `focus-monitor-up`             | Focus the monitor above          |
| `Mod+Shift+Down` / `Mod+Shift+J`  | `focus-monitor-down`           | Focus the monitor below          |
| `Mod+Shift+Ctrl+Left` / `…+H`     | `move-column-to-monitor-left`  | Send column to the left monitor  |
| `Mod+Shift+Ctrl+Right` / `…+L`    | `move-column-to-monitor-right` | Send column to the right monitor |
| `Mod+Shift+Ctrl+Up` / `…+K`       | `move-column-to-monitor-up`    | Send column to the monitor above |
| `Mod+Shift+Ctrl+Down` / `…+J`     | `move-column-to-monitor-down`  | Send column to the monitor below |

## Workspaces

Workspaces stack vertically; move between them with up/down.

| Keybind                               | Action                          | What it does                    |
| ------------------------------------- | ------------------------------- | ------------------------------- |
| `Mod+Page_Down` / `Mod+U`             | `focus-workspace-down`          | Focus the workspace below       |
| `Mod+Page_Up` / `Mod+I`               | `focus-workspace-up`            | Focus the workspace above       |
| `Mod+Ctrl+Page_Down` / `Mod+Ctrl+U`   | `move-column-to-workspace-down` | Send column to workspace below  |
| `Mod+Ctrl+Page_Up` / `Mod+Ctrl+I`     | `move-column-to-workspace-up`   | Send column to workspace above  |
| `Mod+Shift+Page_Down` / `Mod+Shift+U` | `move-workspace-down`           | Reorder this workspace downward |
| `Mod+Shift+Page_Up` / `Mod+Shift+I`   | `move-workspace-up`             | Reorder this workspace upward   |
| `Mod+1` … `Mod+9`                     | `focus-workspace N`             | Jump to workspace N by index    |
| `Mod+Shift+1` … `Mod+Shift+9`         | `move-column-to-workspace N`    | Send column to workspace N      |

## Column & window layout

| Keybind       | Action                                     | What it does                             |
| ------------- | ------------------------------------------ | ---------------------------------------- |
| `Mod+[`       | `consume-or-expel-window-left`             | Pull in / push out a window on the left  |
| `Mod+]`       | `consume-or-expel-window-right`            | Pull in / push out a window on the right |
| `Mod+,`       | `consume-window-into-column`               | Pull the next window into this column    |
| `Mod+.`       | `expel-window-from-column`                 | Push the bottom window out of the column |
| `Mod+R`       | `switch-preset-column-width`               | Cycle column width (1/3 → 1/2 → 2/3)     |
| `Mod+Shift+R` | `switch-preset-window-height`              | Cycle window height presets              |
| `Mod+Ctrl+R`  | `reset-window-height`                      | Reset window height to automatic         |
| `Mod+F`       | `maximize-column`                          | Maximise the focused column              |
| `Mod+Shift+F` | `fullscreen-window`                        | Fullscreen the focused window            |
| `Mod+Ctrl+F`  | `expand-column-to-available-width`         | Grow column into free space              |
| `Mod+C`       | `center-column`                            | Centre the focused column on screen      |
| `Mod+Ctrl+C`  | `center-visible-columns`                   | Centre all fully-visible columns         |
| `Mod+-`       | `set-column-width "-10%"`                  | Shrink column width                      |
| `Mod+=`       | `set-column-width "+5%"`                   | Grow column width                        |
| `Mod+Shift+-` | `set-window-height "-10%"`                 | Shrink window height                     |
| `Mod+Shift+=` | `set-window-height "+5%"`                  | Grow window height                       |
| `Mod+V`       | `toggle-window-floating`                   | Move window between tiling ↔ floating    |
| `Mod+Shift+V` | `switch-focus-between-floating-and-tiling` | Jump focus between the two layers        |
| `Mod+W`       | `toggle-column-tabbed-display`             | Show the column's windows as tabs        |

## Mouse wheel & touchpad scroll

`Mod` + scroll navigates without touching the keyboard. Workspace binds are
rate-limited (`cooldown-ms=150`) so you don't overshoot.

| Keybind                       | Action                                  | What it does                      |
| ----------------------------- | --------------------------------------- | --------------------------------- |
| `Mod+Wheel↓` / `Mod+Wheel↑`   | `focus-workspace-down` / `-up`          | Scroll through workspaces         |
| `Mod+Ctrl+Wheel↓` / `↑`       | `move-column-to-workspace-down` / `-up` | Carry column across workspaces    |
| `Mod+Wheel→` / `Mod+Wheel←`   | `focus-column-right` / `-left`          | Scroll through columns            |
| `Mod+Ctrl+Wheel→` / `←`       | `move-column-right` / `-left`           | Carry column along the strip      |
| `Mod+Shift+Wheel↓` / `↑`      | `focus-column-right` / `-left`          | Vertical wheel → horizontal focus |
| `Mod+Ctrl+Shift+Wheel↓` / `↑` | `move-column-right` / `-left`           | Vertical wheel → horizontal move  |

## System

| Keybind           | Action                              | What it does                                              |
| ----------------- | ----------------------------------- | --------------------------------------------------------- |
| `Mod+Escape`      | `toggle-keyboard-shortcuts-inhibit` | Hand shortcuts to a remote-desktop/KVM app (escape hatch) |
| `Mod+Shift+E`     | `quit`                              | Exit niri (with confirmation)                             |
| `Ctrl+Alt+Delete` | `quit`                              | Exit niri (with confirmation)                             |
| `Mod+Shift+P`     | `power-off-monitors`                | Blank the monitors (any input wakes them)                 |

## Available but not bound

Handy actions left as commented suggestions in the config — uncomment to adopt:

| Suggested bind    | Action                               | Why you might want it                    |
| ----------------- | ------------------------------------ | ---------------------------------------- |
| `Mod+Tab`         | `focus-workspace-previous`           | Flip between the last two workspaces     |
| `Mod+J` / `Mod+K` | `focus-window-or-workspace-down/-up` | Let up/down flow into the next workspace |
| `Mod+Ctrl+1…9`    | `move-window-to-workspace N`         | Move a single window (not the column)    |
| `Mod+Space`       | `switch-layout "next"`               | Cycle xkb keyboard layouts               |

## References

- [Configuration: Key bindings](https://github.com/niri-wm/niri/wiki/Configuration:-Key-Bindings)
- [Configuration: Actions](https://github.com/niri-wm/niri/wiki/Configuration:-Actions)
