# Zed

[Zed](https://zed.dev/) editor config, tracked so a fresh machine comes up
identical. Everything lives under `~/.config/zed/` and is chezmoi-managed from
[`home/dot_config/zed/`](../home/dot_config/zed):

| File            | Purpose                                                      |
| --------------- | ------------------------------------------------------------ |
| `settings.json` | Curated overrides only (not a dump of defaults) + extensions |
| `keymap.json`   | Custom key bindings on top of the VS Code base keymap (none) |

On a Windows host the same two files also go to `%APPDATA%\Zed\` by hand — see
[Windows host + WSL guest](#windows-host--wsl-guest).

Project-scoped settings for a specific repo live in that repo's own `.zed/`
(committed to its git, not chezmoi) — see [Global vs project](#global-vs-project-settings-zed).

Only **intentional overrides** are tracked. To see everything Zed defaults to,
run `zed: open default settings` from the command palette (`Ctrl+Shift+P`); do
not copy it in — defaults drift between versions.

## Install & apply

```sh
chezmoi apply            # writes ~/.config/zed/*
```

On first launch Zed reads `auto_install_extensions` in `settings.json` and pulls
every listed extension automatically — no manual install list to maintain.

External formatters must be on `PATH` (mise provides them): **dprint**, **shfmt**,
**fish_indent**. **Biome** is fetched by its extension, so it needs nothing on
`PATH`. Go needs **gopls** (+ **dlv** for debugging) on `PATH` — `mise` / `just setup`.

### Windows host + WSL guest

Under [ADR 0025](adr/0025-wsl-guest-for-the-terminal-layer-on-windows.md) Zed
runs natively on Windows and opens repos in the WSL guest through Zed's WSL
remote. That makes **two** settings files, both fed from the same source:

| Side                  | File                          | Reads it for                  | Applied by       |
| --------------------- | ----------------------------- | ----------------------------- | ---------------- |
| Client (Windows host) | `%APPDATA%\Zed\settings.json` | UI, fonts, theme, keymap, AI  | hand copy, below |
| Server (WSL guest)    | `~/.config/zed/settings.json` | LSP config, formatter routing | `chezmoi apply`  |

Neither side sees the other's file (both read the repo's `.zed/`), so the guest
is deliberately **not** in the GUI-app block of `.chezmoiignore`. After changing
the source, copy it to the host from inside the guest:

```sh
cp home/dot_config/zed/{settings,keymap}.json \
  "$(wslpath "$(cmd.exe /c 'echo %APPDATA%' 2>/dev/null | tr -d '\r')")/Zed/"
```

Change settings in the repo, not in Zed's Settings UI on Windows — a UI edit
lands only in `%APPDATA%` and drifts until someone notices.

## Per-color-scheme font weight (400 light / 200 dark)

Zed has **no native per-theme font weight** and no CSS injection, so the weight is
driven from outside the editor — by the same darkman transition hook that
re-themes everything else (see [theme-sync.md](theme-sync.md)). The hook
[`set-color-scheme`](../home/dot_local/share/darkman/executable_set-color-scheme)
`sed`-rewrites `buffer_font_weight` in `settings.json` (200 in dark, 400 in
light); Zed hot-reloads it.

The source keeps the **400 light baseline**, so a `chezmoi apply` while in dark
mode shows 400 until the next transition or a manual `Mod+Shift+D` — an accepted,
self-healing transient. Full rationale and alternatives:
[ADR 0013](adr/0013-zed-per-theme-font-weight-via-darkman-hook.md) (the Zed
counterpart of [ADR 0011](adr/0011-vscode-custom-css-for-font-weight.md)).

**On a Windows host the weight stays 400 in both modes.** There is no darkman
there, and nothing else rewrites the file — WezTerm follows the Windows mode for
colours only (its font weight is fixed). Accepted as cosmetic.

> Keep `buffer_font_weight` a single-line integer key — the hook edits it by
> regex.

**Restart Zed once after installing.** Zed watches `settings.json` by _inode_, so
the hook rewrites the file **in place** (truncate + rewrite, same inode) rather
than `sed -i` (which renames to a new inode and silently breaks the watch). A
fresh Zed start binds the watch to the current inode; after that, toggles
hot-reload the weight live. Corollary: changing a setting through Zed's **Settings
UI** rewrites the file to a new inode (you'll see `buffer_font_weight` become
`400.0`) and re-breaks the watch until the next restart — so edit settings as
**text**, not via the UI.

## Extensions — VS Code parity

Zed bundles a lot that needs an extension in VS Code, so the extension list is
short. What each VS Code extension maps to:

| Need                     | Zed                                                             |
| ------------------------ | --------------------------------------------------------------- |
| HTML / CSS / SCSS        | **built-in**                                                    |
| JS / TS / TSX / JSX      | **built-in** (`vtsls`) — see note on tsgo below                 |
| Go                       | **built-in** (gopls) + `golangci-lint`, `templ`                 |
| Rust                     | **built-in** (rust-analyzer)                                    |
| Tailwind                 | **built-in**                                                    |
| ESLint                   | **built-in** (diagnostics; `code_action: source.fixAll.eslint`) |
| auto-rename-tag          | **built-in** (`linked_edits`)                                   |
| Error Lens               | **built-in** (`diagnostics.inline`)                             |
| EditorConfig             | `editorconfig` extension                                        |
| Markdown preview / lint  | **built-in** preview + `markdown-oxide`                         |
| MDX                      | `mdx` extension (srazzak) — TS-in-MDX on via `lsp.mdx-analyzer` |
| GitLens                  | `git-firefly` (blame / history) + native git — see Git, below   |
| Astro / Svelte / Vue     | `astro` / `svelte` / `vue` extensions                           |
| Dockerfile               | `dockerfile` extension                                          |
| Fish                     | `fish` extension (+ `fish_indent` formatter)                    |
| Just / TOML              | `just` / `toml` extensions                                      |
| Biome                    | `biome` extension (LSP + formatter)                             |
| Material icons / Dracula | `material-icon-theme` / `dracula` extensions                    |
| Catppuccin Latte (light) | `catppuccin` extension                                          |

> [!NOTE]
> **tsgo is deliberately not installed.** The `tsgo` extension (TypeScript 7's
> native-preview server, id `typescript-ls`) registers a _second_ TS language
> server for JS/TS/TSX/JSX. With no `language_servers` pin, Zed attaches it
> **alongside** the built-in `vtsls`, so both answer hover/completion/diagnostics
> — the cause of stacked duplicate hover popovers. tsgo also can't load tsserver
> plugins like `@effect/language-service`. We use `vtsls` only. To opt back in
> deliberately, pin it per project in `.zed/`:
> `"language_servers": ["typescript-ls", "!vtsls"]` (replace) or
> `["typescript-ls", "vtsls"]` (tandem fallback — the tsgo docs say this
> "eliminates duplicate diagnostics").

> [!IMPORTANT]
> **Overriding `language_servers` with `"..."` revives a _second_ TS server —
> even without tsgo.** Zed's default TS set is `vtsls` only;
> `typescript-language-server` is registered but **default-disabled**. Two docs
> facts combine to bite: `"..."` re-includes _every_ registered server, and a
> project `.zed/` array **replaces** the global one entirely
> ([configuring-languages](https://zed.dev/docs/configuring-languages)). So the
> moment a repo pins e.g. `["!biome", "..."]` for TS, `"..."` resurrects
> `typescript-language-server` **alongside** `vtsls` → stacked duplicate hovers,
> and a doubled `tsserver` (~1.3 GB wasted). Global settings can't prevent it
> (the project array wins). Fix it in the **same array**; the canonical
> TS-family (`TypeScript` / `TSX` / `JavaScript` / `JSX`) value when dropping
> Biome is:
>
> ```jsonc
> "language_servers": ["!biome", "!typescript-language-server", "..."]
> ```
>
> JSON/CSS/etc. don't attract it, so those stay `["!biome", "..."]`. A repo with
> **no** `.zed/` TS override needs nothing — the global default is already
> single-server. Verify with `pgrep -af typescript-language-server` (should be
> empty) and a one-popover hover.

### Gaps (no Zed extension yet)

- **PandaCSS** — no Zed extension exists. `.ts` files using Panda still get the
  full TypeScript LSP; only Panda's token autocomplete / config awareness is
  missing. Writing one means wrapping Panda's own language server
  ([`@pandacss/language-server`](https://github.com/chakra-ui/panda)) in a Zed
  extension (Rust → WASM) per the
  [Language Extensions guide](https://zed.dev/docs/extensions/languages). Deferred
  — revisit when there's time to build it or a community one appears.
- **pretty-ts-errors** — no equivalent; Zed's TS diagnostics are decent but not
  prettified.

## Formatting & linting

Mirrors the VS Code per-language split. `format_on_save` is `"on"` globally;
languages with no explicit formatter fall back to their language server (gopls,
rust-analyzer, …).

| Language      | Formatter              | Notes                       |
| ------------- | ---------------------- | --------------------------- |
| JS / TS / TSX | Biome (LSP)            | + fixAll + organize imports |
| JSON / JSONC  | Biome (LSP)            |                             |
| Markdown      | dprint (external)      | trailing whitespace kept    |
| YAML / TOML   | dprint (external)      |                             |
| Shell         | shfmt (external)       |                             |
| Fish          | fish_indent (external) |                             |
| Go            | gopls (gofumpt)        | organize imports first      |

ESLint is **diagnostics-only** (for legacy repos that still ship an ESLint
config); new code uses Biome + oxlint, so there is deliberately no
`source.fixAll.eslint` on save.

### Go

`lsp.gopls.initialization_options` turns on `gofumpt`, `staticcheck`, a few
`analyses` (unusedwrite / useany / nilness), and inlay `hints` — mirroring the VS
Code Go setup. Inlay hints only render because `inlay_hints.enabled` is on
globally (Zed has no per-language enable). The per-project import grouping
(`"local": "<module>"`) is deliberately **not** global — it belongs in each Go
repo's own `.zed/settings.json`.

## AI

Two independent layers:

- **Edit predictions** (inline tab completion) — **off** (`"provider": "none"`).
  Zed's own model, Zeta, is no longer on the Free plan (Pro / Student / Business
  only), and Copilot was dropped at work. LSP completions are unaffected. To turn
  predictions back on, pick a provider in `edit_predictions.provider`:

  | Provider                 | Needs                                             |
  | ------------------------ | ------------------------------------------------- |
  | `zed` (Zeta)             | a paid Zed plan                                   |
  | `ollama`                 | a local Ollama + a code base model (`ollama: {}`) |
  | `codestral` / `mercury`  | an API key from Mistral / Inception Labs          |
  | `open_ai_compatible_api` | any OpenAI-completions server (vLLM, llama.cpp)   |

  `mode: "subtle"` (show only while holding `Alt`) and
  `allow_data_collection: "no"` are already set, so a switch back starts quiet
  and private. Claude is not a prediction provider — no Anthropic option exists,
  and it would be too slow for this layer anyway.
- **Agents (ACP)** — `claude-acp` is registered for the Claude Agent. It owns
  its own auth: open a Claude Agent thread and `/login` with the Claude account
  (a Claude Team seat works). That seat does **not** come with an API key, so the
  Zed Agent, the Inline Assistant and the Git panel's "Generate commit message"
  have no model to call — use the Claude Agent thread, and commit in the terminal.
  Each agent is its own thread.

There is no `AGENTS.md` in the Zed config dir. Zed's Rules → Skills migration
writes one there (`%APPDATA%\Zed\AGENTS.md` on Windows) holding the old commit
prompt, which it then injects into every Zed Agent thread — delete it.

API keys are stored in the **system keychain**, never in `settings.json`, so this
config is safe in a public repo.

## Git

Native git covers the daily loop by keyboard: Git panel, Project Diff (split /
unified, editable hunks), per-hunk staging, inline blame, file history, commit,
branch/stash, push/pull/fetch, and button-driven conflict resolution.
`git-firefly` adds GitLens-style blame and history on top (current-line
`inline_blame` is on). What's still missing vs GitLens: interactive rebase UI,
history-graph, and a full repo explorer; the conflict UI is less polished than a
3-pane merge tool.

Heavy git (commit, rebase, conflict resolution) is done in the **terminal**;
Zed's role is reviewing diffs/changes in-editor (`Ctrl+G D`, the Git panel). The
integrated terminal's `EDITOR` is set to `zed --wait`, so a terminal `git commit`
opens its message back in this Zed.

## Keymap cheat-sheet

Base keymap is **VS Code**, so muscle memory carries over. Modifiers: `Ctrl` /
`Alt` / `Shift` are Zed's; **`Super` is niri's** and is never used here (niri
grabs it first). Everything below is a Zed or VS Code base default — `keymap.json`
is currently empty.

### Navigation & files

| Keys           | Action                         |
| -------------- | ------------------------------ |
| `Ctrl+P`       | Quick-open file (fuzzy)        |
| `Ctrl+Shift+P` | Command palette                |
| `Ctrl+Shift+E` | Focus project panel (files)    |
| `Ctrl+B`       | Toggle project panel (sidebar) |
| `Ctrl+\``      | Toggle terminal                |
| `Ctrl+N`       | New file                       |
| `F2`           | Rename symbol                  |
| `Ctrl+Click`   | Go to definition               |

### Tabs & panes

| Keys                | Action                   |
| ------------------- | ------------------------ |
| `Ctrl+Tab`          | Next tab                 |
| `Ctrl+Shift+Tab`    | Previous tab             |
| `Ctrl+W`            | Close tab                |
| `Ctrl+\`            | Split pane               |
| `Ctrl+K` then arrow | Move focus between panes |

### Search

| Keys           | Action                    |
| -------------- | ------------------------- |
| `Ctrl+F`       | Find in file              |
| `Ctrl+H`       | Find & replace in file    |
| `Ctrl+Shift+F` | Find in project           |
| `Ctrl+Shift+H` | Find & replace in project |

### Editing

| Keys            | Action                     |
| --------------- | -------------------------- |
| `Ctrl+D`        | Add next occurrence        |
| `Ctrl+/`        | Toggle line comment        |
| `Alt+↑ / Alt+↓` | Move line up / down        |
| `Ctrl+.`        | Quick fix / code actions   |
| `F8 / Shift+F8` | Next / previous diagnostic |

### Git actions

| Keys               | Action                                      |
| ------------------ | ------------------------------------------- |
| `Ctrl+Shift+G`     | Focus the Git panel                         |
| `Ctrl+G` `D`       | Project Diff (all changes)                  |
| `Ctrl+Y` / `Alt+Y` | Stage hunk & move to next (in Project Diff) |
| `Ctrl+G` `↑ / ↓`   | Push / pull                                 |

Discover any binding with `Ctrl+K Ctrl+S` (open keymap) or the command palette;
the authoritative action list is [zed.dev/docs/all-actions](https://zed.dev/docs/all-actions).

## Global vs project settings (.zed)

Two settings layers, two portability channels:

| Layer       | Location          | Travels via         | Applies to             |
| ----------- | ----------------- | ------------------- | ---------------------- |
| **Global**  | `~/.config/zed/*` | chezmoi (dotfiles)  | every project, per box |
| **Project** | `<repo>/.zed/`    | that repo's own git | only that repo         |

A project `.zed/settings.json` **overrides** the global one for files opened in
that repo (more specific wins — like VS Code workspace vs user). It is committed
to the repo's git, so it clones with the repo — it is **not** chezmoi-managed and
never reaches `$HOME`.

Rule of thumb: **about you** → global (fonts, theme, keymap, AI, your default
tooling). **About the project** → `.zed/` (formatter routing that differs from
your global default, gopls `local` import grouping, repo-specific exclusions).
Only put the _deltas_ there — everything else is inherited from global.

This repo ships its own [`.zed/settings.json`](../.zed/settings.json), the
counterpart of [`.vscode/settings.json`](../.vscode/settings.json): global Zed
formats JSON with Biome, but this repo must use **dprint** (its CI enforces it),
so `.zed/` re-pins md/json/jsonc/yaml/toml → dprint, shell → shfmt, fish →
fish_indent. It also **disables the Biome language server** for JSON/JSONC
(`"language_servers": ["!biome", "..."]`) — global Zed attaches Biome there, but
this repo never uses it, so dropping it per-project stops a redundant server from
loading (the general knob for "don't run this LS in this project"). This repo only
overrides JSON/JSONC, which don't attract a second TS server — but a **TypeScript**
repo using the same `["!biome", "..."]` trick must also add
`!typescript-language-server` (see the IMPORTANT note under
[Extensions](#extensions--vs-code-parity)), or `"..."` silently revives it. It is
written self-contained (every language explicit) so any contributor formats it
correctly regardless of their own global config.

## Gotchas

- **Font weight not changing?** See the restart-once + inode note under
  [Per-color-scheme font weight](#per-color-scheme-font-weight-400-light--200-dark).
  Short version: restart Zed once after install, and edit settings as **text**,
  not via the Settings UI. The swap only fires on a transition, so right after a
  `chezmoi apply` toggle `Mod+Shift+D` once.
- **Saving `home/dot_config/zed/*.json` doesn't reformat it** — and that's
  expected. Those source files are excluded from dprint (they're hand-maintained
  JSONC with trailing commas), so in this repo the dprint formatter no-ops on
  them. The _live_ `~/.config/zed/settings.json` (outside the repo) formats fine
  because it falls under the global Biome routing instead.
- `home/dot_config/zed/**` is excluded from dprint (JSONC with trailing commas),
  so `just fmt` won't touch the global config. The repo-root `.zed/` is **not**
  excluded — it's kept dprint-clean (no trailing commas) like `.vscode/`.
- **"Unsupported GPU / software emulated GPU (llvmpipe)" on launch?** Almost always
  a **pending reboot after an `nvidia`+`linux` upgrade**, not a Zed problem. A
  system upgrade replaces the userspace NVIDIA libs and kernel while the _old_
  kernel module is still loaded — `nvidia-smi` then reports `Driver/library
  version mismatch` and Vulkan enumerates zero GPUs (`vulkaninfo --summary` fails),
  so Zed falls back to `llvmpipe`. **Fix: reboot** — you can't hot-reload it (the
  running kernel's module dir is already gone). Do **not** set
  `ZED_ALLOW_EMULATED_GPU=1`; that only hides the warning while keeping the slow
  software renderer. Confirm the recovery after reboot with `nvidia-smi` (no
  mismatch) and `vulkaninfo --summary` (lists the GeForce, not llvmpipe).
