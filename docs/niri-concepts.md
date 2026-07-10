# niri — concepts & mental model

How niri thinks, so the config and keybinds stop feeling arbitrary. If you only
read one niri doc, read this one. For the config itself see
[niri-config.md](niri-config.md); for every keybind see
[niri-keybindings.md](niri-keybindings.md).

## The one big idea: a scrollable strip

Traditional tilers (i3, sway) cram every window into the visible screen and
shrink the others to make room. niri doesn't. Each workspace is an **infinite
horizontal strip**. New windows are added to the right at a sensible size and
_push the strip wider_ instead of resizing their neighbours. You **scroll** the
strip left/right to bring windows into view.

Consequences worth internalising:

- Opening a window never resizes the ones you already arranged.
- "Off-screen" is normal — a window can sit just past the right edge, one scroll
  away. Nothing is lost, it's only out of view.
- There is no master/stack, no fixed grid. Position is just "where on the strip".

## The hierarchy

```text
Output (monitor)
└── Workspace           ← a vertical stack of workspaces per output
    └── Column          ← the strip is a row of columns
        └── Window      ← a column is a vertical stack of windows
```

| Term          | What it is                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------ |
| **Window**    | One application surface. The atom.                                                         |
| **Column**    | A vertical stack of one or more windows. The unit that scrolls horizontally.               |
| **Workspace** | One horizontal strip of columns. Workspaces stack **vertically** (scroll up/down between). |
| **Output**    | A physical monitor. Each output has its own independent vertical list of workspaces.       |

A lone window is just a column with one window in it. Put two windows in the same
column and they split the column's height between them.

## Two axes, one rule

Movement is 2D and the direction words are literal:

- **Left / Right** move along the strip → between **columns**.
- **Up / Down** move within a column (**windows**) and between **workspaces**.

The single rule that ties every keybind together:

> **A key that _focuses_ somewhere, plus `Ctrl`, _moves_ the focused thing there.**

So `Mod+Right` focuses the column to the right; `Mod+Ctrl+Right` moves the
current column to the right. `Mod+3` focuses workspace 3; `Mod+Shift+3` moves the
column to workspace 3. Learn the focus keys and you already know the move keys.

## Columns: consume, expel, tab

Because a column holds multiple windows, you shuffle windows in and out of it:

- **Consume** — pull the neighbouring window _into_ the current column (they now
  share the column, stacked vertically).
- **Expel** — push a window _out_ of the column into its own column on the strip.
- **Tabbed display** — instead of stacking a column's windows top-to-bottom,
  show them as vertical **tabs** (one visible at a time). Great for a column of
  reference windows you flip between.

## Widths and heights are presets, not pixels

You rarely set exact sizes. niri cycles through **preset column widths** (this
config: 1/3, 1/2, 2/3 of the screen) with one key, and preset window heights with
another. You can still nudge by percentages or pixels for fine control, but the
day-to-day flow is "cycle to the width that fits".

- `maximize-column` — make the focused column fill the screen (others stay on the
  strip, just scrolled off).
- `fullscreen-window` — true fullscreen for one window.
- `expand-column-to-available-width` — grow the column into whatever space the
  other _visible_ columns aren't using.
- `center-column` — scroll so the focused column sits in the middle.

## Floating layer

Every workspace also has a **floating layer** above the tiled strip, for things
that shouldn't tile (dialogs, a PiP video, a scratch terminal). Toggle a window
between tiled and floating, and switch focus between the two layers. Window rules
can open specific apps floating automatically (this config does that for the
`tuxedo` todo TUI).

## Workspaces are dynamic

niri creates and destroys workspaces for you. There is always exactly one empty
workspace at the bottom; fill it and a new empty one appears below. This is why
referring to a workspace by a number past the end just lands on that last empty
one — the count is fluid.

On top of the dynamic ones you can define **named workspaces** that always exist
and can be pinned to a specific monitor. This config names five —
`terminal`, `coding`, `browser`, `chatting`, `tools` — and pins them per machine
(see [niri-config.md](niri-config.md#named-workspaces)).

## Monitors are just more space

Each monitor holds its own vertical list of workspaces. Directional monitor
actions (`focus-monitor-left`, `move-column-to-monitor-right`, …) move focus or
send columns between physically adjacent outputs — which is why output
**position** matters (it defines what "left of" means). The cursor can only cross
between outputs that are directly adjacent in the logical coordinate space.

## Overview

The **Overview** is a zoomed-out view of all workspaces and windows on the
current output — a spatial map you can click or key around in. Reach it with
`Mod+O`, the top-left **hot corner**, or a four-finger swipe up on a touchpad.
It's the fastest way to reorient when the strip has grown large.

## How to explore your running session

niri answers questions about itself over IPC — invaluable when writing config:

```sh
niri msg outputs        # monitors: names, modes, scale, position
niri msg windows        # open windows and their app-id / title (for window rules)
niri msg workspaces     # current workspaces and which output they're on
niri msg --json outputs # same, machine-readable
```

Press `Mod+Shift+/` (the "important hotkeys" overlay) any time to see the live
keybinds for the current session.

## References

- [niri wiki](https://github.com/niri-wm/niri/wiki)
- [Getting started](https://github.com/niri-wm/niri/wiki/Getting-Started)
- [awesome-niri](https://github.com/niri-wm/awesome-niri) — configs, tools, shells
