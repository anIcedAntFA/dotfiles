# Screen recording — wl-screenrec

Video counterpart to [screenshot.md](screenshot.md). Where screenshots are a
one-shot grab, a recording is a **long-running process**: you start it, it runs,
you stop it later — so the wiring is a little different.

## Why wl-screenrec

[wl-screenrec](https://github.com/russelltg/wl-screenrec) is a **GPU-accelerated**
recorder for wlroots-style compositors (niri included). It encodes with VA-API on
the GPU, so it stays cheap on CPU and battery even at high resolution — the reason
to prefer it over the CPU-bound `wf-recorder`. It captures a **region** (via
`slurp`, exactly like the screenshot flow) or a **single output**, with optional
audio.

Two things it deliberately does _not_ do, which shape the script below:

- **No window capture** — it records a rectangle or an output, nothing that
  follows a window.
- **One output at a time** — it can't span multiple monitors in a single file.

## Install

```sh
yay -S --needed wl-screenrec-git slurp jq libnotify
```

- `wl-screenrec-git` — the recorder (AUR; tracks upstream `main`).
- `slurp` — draw the region rectangle (shared with the screenshot pipeline).
- `jq` — read the focused output name from `niri msg --json`.
- `libnotify` — `notify-send`, the only signal a recording is live.

Hardware encoding needs a working VA-API driver for your GPU — see the next
section, which is where the one real setup snag lives.

## VA-API / hardware encoding

wl-screenrec encodes h264 **on the GPU** via VA-API, so it needs a VA-API driver
that supports your GPU. On Intel there are **two** drivers, and picking the wrong
one fails hard:

- **`intel-media-driver`** — the `iHD` driver, for **Gen8+** (Broadwell and newer,
  including this box's Alder Lake **UHD 770**). The modern one.
- **`libva-intel-driver`** — the legacy `i965` driver, only up to ~Gen9. On a
  Gen12 GPU it can't initialise at all.

If only `libva-intel-driver` is present, VA-API tries `i965` and dies — the
recorder even tells you it's not its own bug:

```text
[VAAPI] libva: /usr/lib/dri/i965_drv_video.so init failed
[VAAPI] Failed to initialise VAAPI connection: -1 (unknown libva error).
[ERROR] failed to create encoder(s): Failed to load vaapi device: Input/output error.
thread 'main' panicked at src/main.rs: enc left in intermediate state
```

Fix (per [wl-screenrec#30](https://github.com/russelltg/wl-screenrec/issues/30)) —
install the iHD driver and `vainfo` to check it:

```sh
yay -S --needed intel-media-driver libva-utils
vainfo   # from libva-utils
```

A healthy `vainfo` names the **iHD** driver and lists `VAProfileH264*` with
`VAEntrypointEncSlice` — the hardware h264 _encode_ path wl-screenrec needs:

```text
vainfo: Driver version: Intel iHD driver for Intel(R) Gen Graphics ...
      VAProfileH264High    : VAEntrypointEncSlice
```

No working VA-API (or a non-Intel GPU without its own driver)? `wl-screenrec
--no-hw` falls back to a CPU encoder — heavier on battery, but it records.

## The `dot-screenrec` script

[`home/dot_local/bin/executable_dot-screenrec`](../home/dot_local/bin/executable_dot-screenrec)
wraps the tool. Because a niri keybind has no terminal to `Ctrl-C`, **stopping is
a separate command** that sends `SIGINT` to the running encoder (wl-screenrec
finalizes the `.mp4` cleanly on that signal):

```sh
dot-screenrec region          # slurp a rectangle, then record it
dot-screenrec screen          # record the focused monitor
dot-screenrec stop            # finish & save the running recording

dot-screenrec region audio    # add the default audio source (opt-in)
dot-screenrec screen audio
```

How it behaves:

- **Single instance.** State (PID + target path) lives in
  `$XDG_RUNTIME_DIR/dot-screenrec.state`. Starting a mode while a recording is
  already running is refused with a notification — stop the current one first.
- **Silent by default.** Audio is opt-in via a trailing `audio` arg (adds
  `--audio`), so a public repo never captures your mic by accident.
- **Web-ready output.** Files are `.mp4` with `--codec avc` (h264), which plays
  inline in any browser `<video>` — no transcode before a blog embed. They land
  in `$XDG_VIDEOS_DIR` as `Screencast from <timestamp>.mp4`.
- **Feedback.** `notify-send` fires a fresh notification on start
  (`● Recording — region`) and on stop (the saved path).

## Keybinds

The `Mod+Backslash` family, parallel to the `Mod+S` screenshot family (see
[niri-keybindings.md](niri-keybindings.md#screenshots--capture)). `Backslash`
rather than `Print` so it works on keyboards without a dedicated `Print` key:

| Keybind               | Command                | Action                 |
| --------------------- | ---------------------- | ---------------------- |
| `Mod+Backslash`       | `dot-screenrec region` | Start: select a region |
| `Mod+Shift+Backslash` | `dot-screenrec screen` | Start: focused monitor |
| `Mod+Ctrl+Backslash`  | `dot-screenrec stop`   | Stop & save            |

Audio variants aren't bound by default — run them from a terminal, or add a bind
passing the `audio` arg if you record talking demos often.

## References

- [wl-screenrec README](https://github.com/russelltg/wl-screenrec)
- [slurp](https://github.com/emersion/slurp)
