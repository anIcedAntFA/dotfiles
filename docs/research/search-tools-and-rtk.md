# Search tools (grep, find, ripgrep, fd), RTK, and Claude Code hook semantics

Research note — investigated 2026-10-11. Five questions, one section each:
(1) how Claude Code resolves several `PreToolUse` hooks on one Bash call,
(2) ripgrep internals and filtering rules, (3) fd internals and filtering rules,
(4) what RTK ("Rust Token Killer") does to `grep`/`find` and how it counts
savings, (5) grep/find background for a comparison article.

Machine context (verified, see the last-but-one section): EndeavourOS, ripgrep
15.2.0 (+pcre2), fd 10.5.0, rtk 0.45.0, GNU grep 3.12, GNU findutils 4.11.0.
`$RIPGREP_CONFIG_PATH` points at `~/.config/ripgrep/config` (`--smart-case`,
`--hidden`, `--glob=!.git/`, `--glob=!vendor/`), and `~/.config/fd/ignore`
holds `.git/` and `vendor/`.

> How the sources were read. Claude Code docs were downloaded as raw Markdown
> (`https://code.claude.com/docs/en/<page>.md`) and quoted from the file.
> ripgrep, fd and rtk were shallow-cloned at the installed tags (`15.2.0`,
> `v10.5.0`, `v0.45.0`) and read from the working tree; man pages are the ones
> installed here. The POSIX pages, the GNU grep manual and the Haertel post
> were read through a fetch tool that returns extracted quotes, so treat that
> wording as near-verbatim and re-check before quoting it in a blog post.

## TL;DR

- **Deny wins.** With two `PreToolUse` hooks on one Bash call, one `deny` and
  one `allow` + `updatedInput`, the call is blocked. Documented precedence is
  `deny` > `defer` > `ask` > `allow`. Hooks run in parallel and all run to
  completion, so a `deny` does not stop the other hook's side effects.
- **`.ignore` is the one file that un-ignores for both tools.** A line
  `!.claude/` in `.ignore` overrides `.gitignore` for both `rg` and `fd`.
  `.rgignore` only affects rg, `.fdignore` only affects fd. A whitelist match
  also lifts the hidden-file filter for that path, so `--hidden`/`-H` is not
  even needed.
- **ripgrep and fd share their walker.** fd depends on the `ignore`, `regex`
  and `globset` crates from the ripgrep repo, which is why the precedence rules
  are the same.
- **`rtk grep` no longer substitutes ripgrep.** In rtk 0.45.0 `rtk grep` runs
  the real `grep` and `rtk rg` runs the real `rg`; neither adds ignore rules of
  its own. `rtk find` is the exception: it is a reimplementation on the
  `ignore` crate, always respects gitignore, skips hidden entries, and has no
  flag to turn that off.
- **`rtk gain` tokens are `bytes / 4`** of raw vs filtered command output. The
  percentage is a byte ratio; the absolute counts are estimates.
- **find has no ignore concept at all**; every exclusion is an explicit
  expression. Several find tests (`-perm`, `-newer FILE`, `-links`, `-inum`,
  access/change times, `-o`/`!`/parentheses) have no fd equivalent.

## 1. Claude Code hook semantics

Sources: Claude Code hooks reference <https://code.claude.com/docs/en/hooks>,
hooks guide <https://code.claude.com/docs/en/hooks-guide>, memory page
<https://code.claude.com/docs/en/memory>, environment variables
<https://code.claude.com/docs/en/env-vars>, `.claude` directory page
<https://code.claude.com/docs/en/claude-directory>.

### Two PreToolUse hooks, one denies, one allows with a rewrite

- **Execution model.** "All matching hooks run in parallel. If you define the
  same handler in more than one settings file, it runs once. A plugin's or
  skill's copy of the same handler stays separate." (hooks reference, "Hook
  handler fields")
- **All hooks finish before anything is decided.** "When multiple hooks match
  the same event, every hook's command runs to completion before Claude Code
  merges the results. One hook returning `deny` doesn't stop sibling hooks from
  executing. Don't rely on one hook's `deny` to suppress side effects in another
  hook." (hooks guide, "Combine results from multiple hooks")
- **Precedence.** "When multiple PreToolUse hooks return different decisions,
  precedence is `deny` > `defer` > `ask` > `allow`." (hooks reference,
  "PreToolUse decision control"). The guide says the same: "the most restrictive
  answer applies, in the order `deny`, `defer`, `ask`, `allow`. Text from
  `additionalContext` is kept from every hook and passed to Claude together."
- **So: deny wins.** The tool call is prevented; the other hook's `allow` and
  its `updatedInput` have nothing left to apply to. The exit-code form counts
  the same way: "A hook that blocks by exiting 2 routes the same way as
  `"deny"`: Claude sees the stderr message as the denial reason."
- **Competing rewrites are a different story.** "When multiple `PreToolUse`
  hooks return `updatedInput` to rewrite a tool's arguments, the last one to
  finish takes effect. Since hooks run in parallel, the order is
  non-deterministic. Avoid having more than one hook modify the same tool's
  input." (hooks guide, "Limitations and troubleshooting")
- **Settings deny rules still apply after a hook `allow`.** "Deny and ask rules
  are still evaluated regardless of what the hook returns", and "Claude Code
  evaluates permission rules ... against the input your hook returns, not the
  input Claude sent." (`permissionDecision` / `updatedInput` rows)

Not stated by the docs:

- No sentence says "every hook receives the original, unmodified tool input".
  It follows from parallel execution plus the "last one to finish" rule (no
  hook's output exists while another is starting), but it is an inference.
- What Claude Code does with `updatedInput` returned **without** a
  `permissionDecision`. The field table only says "Combine with `"allow"` to
  auto-approve, or `"ask"` to show the modified input to the user." This
  matters here because that is exactly what `rtk hook claude` emits when no
  allow rule matches (section 4).

### PreToolUse input on stdin

"Command hooks receive JSON data via stdin". The documented example for a Bash
call (hooks reference, "Common input fields"):

```json
{
  "session_id": "abc123",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/home/user/my-project",
  "scratchpad_dir": "/tmp/claude-1000/-home-user-my-project/abc123/scratchpad",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test",
    "description": "Run test suite",
    "timeout": 120000,
    "run_in_background": false
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

- Common fields: `session_id`, `prompt_id` (absent until the first user input),
  `transcript_path`, `cwd`, `scratchpad_dir`, `permission_mode`, `effort`,
  `hook_event_name`; `agent_id` / `agent_type` when the hook fires inside a
  subagent. "Not all events receive" `permission_mode`.
- PreToolUse adds `tool_name`, `tool_input`, `tool_use_id`. Bash `tool_input`
  fields: `command` (string), `description` (optional), `timeout` (optional,
  ms), `run_in_background` (boolean).

### Output shapes for denying

JSON form: exit 0 and print one JSON object on stdout.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked by hook"
  }
}
```

- `permissionDecisionReason` for `deny` is "shown to Claude"; for `allow` and
  `defer` it is "written to the debug log only".
- Top-level `decision` / `reason` are "deprecated for this event"; the old
  values `"approve"` and `"block"` map to `"allow"` and `"deny"`.
- stdout is parsed as JSON only "when the whole output is one JSON object with
  nothing around it but whitespace".

Exit-code form: write the reason to stderr and `exit 2`.

```bash
#!/bin/bash
input=$(cat)
command=$(jq -r '.tool_input.command' <<<"$input")

if [[ "$command" == rm* ]]; then
  echo "Blocked: rm commands are not allowed" >&2
  exit 2
fi

exit 0
```

- "Exit with code 2 to block the action. ... a `PreToolUse` hook blocks the
  tool call". "The message that comes with the block is your hook's stderr. If
  your hook also printed JSON that makes a blocking decision, Claude Code uses
  that decision's reason instead."
- Exit 2 cannot be undone by JSON: "Even a `permissionDecision` of `"allow"`
  doesn't let the action through."
- Exit 1 is **not** a block: "Without valid JSON on stdout, Claude Code treats
  exit code 1 as a non-blocking error ... If your hook is meant to enforce a
  policy, use `exit 2`."
- "Choose one approach per hook: either use exit codes alone for signaling, or
  exit 0 and print JSON for structured control."

Allow-with-rewrite, for completeness: `updatedInput` "Replaces the entire input
object, so include unchanged fields alongside modified ones."

### Where hooks are registered

`hooks` key in a settings file; three levels: event, matcher group, handlers.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh"
          }
        ]
      }
    ]
  }
}
```

| Location                      | Scope                            |
| ----------------------------- | -------------------------------- |
| `~/.claude/settings.json`     | All your projects                |
| `.claude/settings.json`       | Single project, committable      |
| `.claude/settings.local.json` | Single project, not committed    |
| Managed policy settings       | Organization-wide                |
| Plugin `hooks/hooks.json`     | When the plugin is enabled       |
| Skill / subagent frontmatter  | While that skill/agent is active |

"Hook entries merge across settings levels rather than replacing each other".
Hooks from settings files "also run inside subagents".

### CLAUDE.md `@file` imports and CLAUDE_CONFIG_DIR

- Syntax and resolution: "CLAUDE.md files can import additional files using
  `@path/to/import` syntax." "Both relative and absolute paths are allowed.
  Relative paths resolve relative to the file containing the import, not the
  working directory. Imported files can recursively import other files, with a
  maximum depth of four hops." (memory page, "Import additional files")
- `~` paths: the docs give `@~/.claude/my-project-instructions.md` as a
  working example of a home-directory import. They do not describe the
  expansion rule beyond that example.
- Imports inside code spans and fenced code blocks are skipped.
- Trust: an import from a project file that resolves outside the working
  directory triggers a one-time approval dialog. User-scope files "such as
  `~/.claude/CLAUDE.md`" load their imports "without the dialog".
- `CLAUDE_CONFIG_DIR`: "Override the configuration directory (default:
  `~/.claude`). All settings, session history, and plugins are stored under
  this path. ... Useful for running multiple accounts side by side" (env-vars).
  And: "If you set `CLAUDE_CONFIG_DIR`, every `~/.claude` path on this page
  lives under that directory instead." (`.claude` directory page, which is the
  page that lists `~/.claude/CLAUDE.md`).
- Putting those together: `$CLAUDE_CONFIG_DIR/CLAUDE.md` is the user-level
  file, and a relative import such as `@RTK.md` in it resolves to
  `$CLAUDE_CONFIG_DIR/RTK.md` because resolution is relative to the importing
  file. No docs sentence states this combination outright, and it was not
  tested here. An import written as `@~/.claude/RTK.md` would keep pointing at
  the literal `~/.claude`, not at the override directory; that is by reading
  the path, not from a doc statement.
- In a settings-file `env` block the value must be absolute: "No shell
  processes them, so shorthand such as `~` or `$HOME` stays as typed." Project
  and local settings cannot set `CLAUDE_CONFIG_DIR`.

## 2. ripgrep internals and semantics

Sources: ripgrep repo at tag `15.2.0` <https://github.com/BurntSushi/ripgrep>
(`README.md`, `GUIDE.md`, `FAQ.md`, `crates/ignore/src/walk.rs`,
`crates/ignore/src/dir.rs`, `crates/core/flags/hiargs.rs`) and `rg(1)` as
installed.

### Regex engines

- Default engine is Rust's `regex` crate. "ripgrep's default regex engine uses
  finite automata and guarantees linear time searching. Because of this,
  features like backreferences and arbitrary look-around are not supported."
  (`rg(1)`, DESCRIPTION)
- Why: "the default regex engine is implemented using finite state machines in
  order to guarantee a linear worst case time complexity on all inputs.
  Backreferences are not possible to implement in this paradigm, and lookaround
  appears difficult to do efficiently." (FAQ, "How do I use lookaround and/or
  backreferences?")
- Syntax is "Perl-like regexes without look-around or backreferences. This
  makes them very similar to the 'extended' (ERE) regular expressions supported
  by _egrep_, but with a few additional features like Unicode character
  classes." (`rg(1)`, REGEX SYNTAX)
- PCRE2 is optional and opt-in: `-P/--pcre2`, or `--engine=default|pcre2|auto`
  (`--auto-hybrid-regex` is the older spelling of `auto`). "Note that PCRE2 is
  an optional ripgrep feature. If PCRE2 wasn't included in your build of
  ripgrep, then using this flag will result in ripgrep printing an error
  message and exiting." The build here has it (`features:+pcre2`).
- A very large pattern set can overflow the lazy DFA cache and "spill over to a
  slower but more robust regular expression engine"; `--dfa-size-limit` raises
  the cache (FAQ, "How do I make the `-f/--file` flag faster?").

### Why it is fast (README, "Is it really faster than everything else?")

- "Rust's regex engine uses finite automata, SIMD and aggressive literal
  optimizations to make searching very fast."
- "Rust's regex library maintains performance with full Unicode support by
  building UTF-8 decoding directly into its deterministic finite automaton
  engine."
- "It supports searching with either memory maps or by searching incrementally
  with an intermediate buffer. The former is better for single files and the
  latter is better for large directories. ripgrep chooses the best searching
  strategy for you automatically."
- Ignore patterns are applied "using a `RegexSet`. That means a single file
  path can be matched against multiple glob patterns simultaneously."
- "It uses a lock-free parallel recursive directory iterator, courtesy of
  `crossbeam` and `ignore`."

Source-level detail behind two of those:

- **Parallel walk.** `crates/ignore/src/walk.rs` implements `WalkParallel`
  with one "work-stealing stack" per thread built on
  `crossbeam_deque::{Stealer, Worker}`. `-j/--threads` "sets the approximate
  number of threads to use. A value of 0 (which is the default) causes ripgrep
  to choose the thread count using heuristics."
- **mmap heuristic.** In `crates/core/flags/hiargs.rs`, automatic mode picks
  memory maps only when `paths.len() <= 10` and every path is a file ("If
  we're only searching a few paths and all of them are files, then memory maps
  are probably faster"); a directory search uses buffered reads. `--mmap` /
  `--no-mmap` force it. Caveat from the man page: ripgrep "may abort
  unexpectedly when memory maps are used if it searches a file that is
  simultaneously truncated."

The README only names "aggressive literal optimizations" without describing
them. The detail lives in the author's blog post the README links
(<https://blog.burntsushi.net/ripgrep/>) and in the `regex` crate; neither was
read for this note.

### Binary detection

- "a file is considered 'binary' if and only if it contains a `NUL` byte
  somewhere in its contents." (GUIDE, "Binary data")
- Three modes: default (stop at the first NUL, drop the file), `--binary`
  (keep searching, report "binary file matches" instead of printing the line),
  `-a/--text` (no detection at all).
- The default mode "only applies to files searched by ripgrep as a result of
  recursive directory traversal"; a file named on the command line is searched
  in binary mode automatically.
- Detection depends on the read strategy: "When ripgrep uses memory maps, then
  binary detection is only performed on the first few kilobytes of the file in
  addition to every matching line. When ripgrep doesn't use memory maps, then
  binary detection is performed on all bytes searched."

### What is skipped by default

`rg(1)`, AUTOMATIC FILTERING: "ripgrep does four types of filtering
automatically: 1. Files and directories that match ignore rules are not
searched. 2. Hidden files and directories are not searched. 3. Binary files
(files with a NUL byte) are not searched. 4. Symbolic links are not followed."

- Hidden means "its base name starts with a dot character (`.`)".
- Gitignore sources honoured: global rules (`core.excludesFile`, default
  `$HOME/.config/git/ignore`), `.gitignore` files including parents in the same
  repository, and `.git/info/exclude`.
- `.gitignore` is only honoured inside a git repository unless
  `--no-require-git` is given.
- Known mismatch with git: "a file that is ignored via `.gitignore` but is
  tracked by git would not be searched by ripgrep even though git tracks it.
  This is unlikely to ever be fixed."

### Flags, exactly

| Flag                  | Meaning (`rg(1)`)                                                                                                                               |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `-u`                  | "equivalent to `--no-ignore`"                                                                                                                   |
| `-uu`                 | "equivalent to `--no-ignore --hidden`"                                                                                                          |
| `-uuu`                | "equivalent to `--no-ignore --hidden --binary`"                                                                                                 |
| `-.` / `--hidden`     | Search hidden files and directories                                                                                                             |
| `--no-ignore`         | Ignore files "such as `.gitignore`, `.ignore` and `.rgignore` will not be respected"; implies the dot, exclude, global, parent and vcs variants |
| `--no-ignore-vcs`     | Drop `.gitignore`-family rules, keep `.ignore` / `.rgignore`                                                                                    |
| `--no-ignore-dot`     | Drop `.ignore` / `.rgignore`, keep gitignore rules                                                                                              |
| `--no-ignore-exclude` | Drop `.git/info/exclude`                                                                                                                        |
| `--no-ignore-global`  | Drop the global gitignore                                                                                                                       |
| `--no-ignore-parent`  | Drop ignore files from parent directories                                                                                                       |
| `--no-ignore-files`   | Drop every `--ignore-file=PATH`                                                                                                                 |

- `--no-ignore` "does not imply `--no-ignore-files`".
- After `-uuu`: "The only filtering ripgrep still does ... is to skip symbolic
  links and to avoid printing matches from binary files." And "`rg -uuu` should
  search the same exact content as `grep -r`."
- `--hidden` is separate from VCS handling: it "will include files and folders
  like `.git` regardless of `--no-ignore-vcs`. To exclude such paths when using
  `-./--hidden`, you must explicitly ignore them using another flag or ignore
  file." Verified: stock `rg --hidden --files` in a fresh repo lists 18 files
  under `.git/`.
- GUIDE.md words `-u` as "will disable `.gitignore` handling"; the man page is
  the precise one (`-u` = `--no-ignore`, which also covers `.ignore` and
  `.rgignore`).

### Precedence among ignore sources

`rg(1)`: "The precedence of ignore rules is as follows, with later items
overriding earlier items":

1. Files given by `--ignore-file`
2. Global gitignore rules
3. Local rules from `.git/info/exclude`
4. Rules from `.gitignore`
5. Rules from `.ignore`
6. Rules from `.rgignore`

- Above all of them sit command-line globs: `-g/--glob` "always overrides any
  other ignore logic". The `ignore` crate docs put it as: "First, glob
  overrides are checked. If a path matches a glob override, then matching
  stops." (`walk.rs`, `WalkBuilder` docs)
- Type beats nesting: "precedence between different types of ignore files is
  not impacted by the directory hierarchy; any `.ignore` file overrides all
  `.gitignore` files. Within each precedence level, more nested ignore files
  have a higher precedence than less nested ignore files." (`walk.rs`)
- The code matches the docs: `matched_ignore` in `crates/ignore/src/dir.rs`
  ends with `m_custom_ignore.or(m_ignore).or(m_gi).or(m_gi_exclude)
  .or(m_global).or(m_explicit)`, and ripgrep registers `.rgignore` as the
  custom ignore filename (`hiargs.rs`).

### Does `!.claude/` in `.ignore` or `.rgignore` beat `.gitignore`?

Yes, by documentation and by experiment (section 3, experiment).

- GUIDE gives the exact case: with `log/` in `.gitignore`, put `!log/` in
  `.ignore`; "ripgrep treats `.ignore` files with higher precedence than
  `.gitignore` files (and treats `.rgignore` files with higher precedence than
  `.ignore` files). This means ripgrep will see the `!log/` whitelist rule first
  and search that directory."
- man page: "if `foo` were in a `.gitignore` and `!foo` were in an
  `.rgignore`, then `foo` would not be ignored".
- Bonus effect on hidden paths: "if a hidden file or a directory is whitelisted
  in an ignore file, then it will be searched even if this flag isn't
  provided." In `dir.rs` the hidden check only runs when no rule matched
  (`if m.is_none() && self.inner.opts.hidden && is_hidden(dent)`).
- A glob override still wins over the whitelist: `rg --hidden -g '!.claude/'`
  hides the directory again (verified).

### Config file vs command line

- Only `$RIPGREP_CONFIG_PATH` is read: "ripgrep will not look in any
  predetermined directory for a config file automatically." (GUIDE)
- Format: "Every line is a shell argument, after trimming whitespace" and
  lines starting with `#` are comments. "there is no escaping."
- Interaction: ripgrep "will behave as if the arguments in this file were
  prepended to any explicit arguments given to ripgrep on the command line."
  "Conflicts between configuration files and explicit arguments are handled
  exactly like conflicts in the same command line invocation" — later wins, so
  `rg foo --case-sensitive` overrides a config `--smart-case` (verified).
- `--no-config` disables it entirely, including the environment variable.
- Consequence for this repo's config: `--glob=!.git/` and `--glob=!vendor/`
  are glob overrides, the highest-precedence layer, so no ignore-file whitelist
  can bring `.git/` or `vendor/` back. Only `--no-config` or a later `-g` can.

## 3. fd internals and semantics

Sources: fd repo at tag `v10.5.0` <https://github.com/sharkdp/fd>
(`README.md`, `Cargo.toml`, `src/walk.rs`) and `fd(1)` as installed.

### What it is built on

- `Cargo.toml` depends on `ignore = "0.4.25"`, `regex = "1.12.2"`,
  `regex-syntax`, `globset`, `aho-corasick`, `crossbeam-channel`.
- README: "Concerning _fd_'s speed, a lot of credit goes to the `regex` and
  `ignore` crates that are also used in ripgrep".
- `src/walk.rs` builds an `ignore::WalkBuilder`, runs it as `WalkParallel`,
  and calls `add_custom_ignore_filename(".fdignore")`. So the precedence logic
  in section 2 is literally the same code, with `.fdignore` in the slot ripgrep
  gives `.rgignore`.

### Pattern mode

- "By default fd uses regular expressions for the pattern. However, this can
  be changed to use simple glob patterns with the `--glob` option." (`fd(1)`)
- Smart case: "By default, fd uses case-insensitive searches, unless the
  pattern contains an uppercase character (smart case)." `-s` and `-i` force
  one or the other.
- Target: "By default, the search pattern is only matched against the filename
  (or directory name). Using this flag [`-p/--full-path`], the pattern is
  matched against the full path."
- Also `-F/--fixed-strings` (literal substring), `--exact`, `--and pattern`.
- Regex syntax is the `regex` crate's; glob syntax is `globset`'s.

### What fd skips by default

"By default fd will exclude hidden files and directories, as well as any files
that match gitignore rules or ignore rules in `.ignore` or `.fdignore` files."
Symlinked directories are not descended into without `-L`.

### Flags, exactly (`fd(1)`)

| Flag                    | Meaning                                                                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-H` / `--hidden`       | Include hidden files and directories. "Ignored files are still excluded unless `--no-ignore` or `--no-ignore-vcs` is also used."                 |
| `-I` / `--no-ignore`    | Show results otherwise ignored by `.gitignore`, `.git/info/exclude`, the global gitignore, `.ignore`, `.fdignore`, and the global fd ignore file |
| `-u` / `--unrestricted` | "an alias for `--hidden --no-ignore`"                                                                                                            |
| `--no-ignore-vcs`       | Drop only the gitignore family (`.gitignore`, `.git/info/exclude`, global gitignore)                                                             |
| `--no-ignore-parent`    | Drop ignore files in parent directories                                                                                                          |
| `--no-require-git`      | Respect gitignore rules outside a git repository too                                                                                             |
| `-E` / `--exclude`      | Exclude by glob. "This overrides any other ignore logic."                                                                                        |
| `--ignore-file`         | Extra gitignore-format file. "These files have a low precedence."                                                                                |

Unlike ripgrep, a single `-u` already includes hidden files, and fd has no
binary-content filter because it never reads file contents.

### Ignore files and their precedence

Files read: `.gitignore`, `.git/info/exclude`, global gitignore, `.ignore`,
`.fdignore`, and the global `$XDG_CONFIG_HOME/fd/ignore` (falling back to
`$HOME/.config/fd/ignore`).

- `.fdignore` "works similarly to a `.gitignore` file anywhere in the searched
  tree ... However, this file is specific to fd, and will be used even if the
  `--no-ignore-vcs` option is used."
- README: "`fd` also supports `.ignore` files that are used by other programs
  such as `rg` or `ag`."
- **Neither the fd README nor the man page states a precedence order.** It
  comes from the `ignore` crate, as wired in `src/walk.rs`:
  1. `-E/--exclude` (glob overrides): highest.
  2. `.fdignore` (custom ignore filename).
  3. `.ignore`.
  4. `.gitignore`, then `.git/info/exclude`, then the global gitignore.
  5. Global fd ignore file and `--ignore-file` files, both added with
     `builder.add_ignore(...)`, i.e. the crate's "explicitly added ignore
     files", lowest.
- Experiments consistent with that order: `.fdignore` containing `.claude/`
  beats `.ignore` containing `!.claude/`; a global fd ignore of `src/` is
  undone by `!src/` in either `.ignore` or `.gitignore`; `-E .claude` beats an
  `.ignore` whitelist.

### Config file or default-flags variable

None.

- `fd(1)`, ENVIRONMENT lists only `LS_COLORS`, `NO_COLOR`, and
  `XDG_CONFIG_HOME` / `HOME` ("Used to locate the global ignore file").
- The man page's own advice is a wrapper: "You can use a shell alias or a
  wrapper script in order to pass desired flags to fd by default."
- The global ignore file is the only persistent knob: "If you add `.git/` to
  your global ignore file ... then `.git` folders will be ignored by default,
  even when the `--hidden` option is used." Verified: with an empty config
  home `fd -H -t f` lists 18 files under `.git/`; with `.git/` in the global
  ignore it lists none.

### Command execution

- `-x/--exec`: "Execute command for each search result in parallel (use
  `--threads=1` for sequential command execution)." Order is
  non-deterministic.
- `-X/--exec-batch`: "Execute command once, with all search results as
  arguments." `--batch-size` caps arguments per invocation.
- Placeholders: `{}` path, `{/}` basename, `{//}` parent, `{.}` path without
  extension, `{/.}` basename without extension. "If no placeholder is present,
  an implicit `{}` at the end is assumed."
- Arguments after `-x` belong to the command; end the list with `\;` to give
  more fd options. Both flags may be repeated.
- With `-x`, `-X` or `-0`, relative paths get a `./` prefix "to reduce the risk
  of a path starting with `-` being treated as a command line option".
- Shell aliases and functions cannot be used as the command (README
  troubleshooting).

### Experiment: which single file un-ignores `.claude/` for both tools?

Setup, in a throwaway git repo under the session scratchpad:

```sh
git init -q .
printf '.claude/\n' > .gitignore
mkdir -p .claude src
printf 'NEEDLE_XYZ in claude\n' > .claude/notes.md
printf 'NEEDLE_XYZ in src\n'    > src/a.txt
```

Each row adds exactly one file containing the single line `!.claude/`, runs
both tools, then removes it. Run with `RIPGREP_CONFIG_PATH` unset and `HOME` /
`XDG_CONFIG_HOME` pointed at an empty directory, so no global gitignore, fd
ignore file or ripgrep config can interfere.

| Whitelist file | `rg --no-config --hidden -l NEEDLE_XYZ` | `fd -H notes`      |
| -------------- | --------------------------------------- | ------------------ |
| none           | `src/a.txt`                             | (nothing)          |
| `.ignore`      | `.claude/notes.md`, `src/a.txt`         | `.claude/notes.md` |
| `.rgignore`    | `.claude/notes.md`, `src/a.txt`         | (nothing)          |
| `.fdignore`    | `src/a.txt`                             | `.claude/notes.md` |

Result: **`.ignore` is the only single file that un-ignores the directory for
both tools.** `.rgignore` and `.fdignore` each work for their own tool only.

Further observations from the same repo:

- With `.ignore` in place the hidden filter is lifted too:
  `rg --no-config -l NEEDLE_XYZ` and `fd notes` (no `--hidden` / `-H`) both
  return `.claude/notes.md`.
- `rg --debug` shows the rule firing: `whitelisting ./.claude:
  Whitelist(IgnoreMatch(Gitignore(Glob { from: Some("./.ignore"), original:
  "!.claude/", ... is_whitelist: true, is_only_dir: true })))`.
- `!.claude` (no trailing slash) works the same.
- A file-level whitelist cannot reach into an ignored directory:
  `.gitignore` = `.claude/` with `.ignore` = `!.claude/notes.md` finds nothing
  in either tool, because the directory is never entered. With `.gitignore` =
  `.claude/*` the same file-level whitelist works.
- `--no-ignore-dot` turns the whitelist off again for rg.
- The parent `.ignore` applies when searching from inside `.claude/`.
- With the real config of this machine (`rg` reading
  `~/.config/ripgrep/config`, `fd` reading `~/.config/fd/ignore`) the `.ignore`
  whitelist still works for both.

## 4. RTK (Rust Token Killer)

Sources: rtk repo at tag `v0.45.0` <https://github.com/rtk-ai/rtk>
(`README.md`, `hooks/README.md`, `hooks/claude/`, `docs/guide/`,
`src/filters/README.md`, `CHANGELOG.md`, and the source files named below) and
`rtk --help` output on this machine. Upstream is already at v0.49.0; everything
here describes 0.45.0.

### What it is

"RTK intercepts shell commands and compresses their output before your agent
reads it." (README) It is a single Rust binary used as a prefix (`rtk git
status`, `rtk grep ...`) that runs the real tool, filters stdout, and prints
the short version. "Four strategies applied per command type": smart
filtering, grouping, truncation, deduplication.

### Claude Code integration

- `rtk init -g` "Install hook + RTK.md (recommended)". It patches the Claude
  settings file with a `PreToolUse` entry (`"matcher": "Bash"`, one `command`
  handler), writes `RTK.md` next to the user-level `CLAUDE.md`, and adds an
  `@RTK.md` reference line to `CLAUDE.md` (`src/hooks/init.rs`). Variants:
  `--hook-only`, `--auto-patch`, `--no-patch`, `--dry-run`, `--show`,
  `--uninstall`.
- `init.rs` resolves the Claude directory from `$CLAUDE_CONFIG_DIR` first and
  falls back to `~/.claude` (`resolve_claude_dir`). Combined with the relative
  `@RTK.md` import, an install per config directory is self-contained.
- `RTK.md` is the short awareness file (source: `hooks/claude/rtk-awareness.md`)
  that lists the meta commands and says everything else is rewritten by the
  hook.
- `rtk hook claude` "Process Claude Code PreToolUse hook (reads JSON from
  stdin)". It reads `tool_input.command`, asks the rewrite registry, and prints
  a `hookSpecificOutput` with `updatedInput` (the original `tool_input` with
  `command` replaced). An older shell hook, `hooks/claude/rtk-rewrite.sh`,
  does the same through `rtk rewrite` and `jq`.
- `rtk rewrite "<cmd>"` is the dry-run entry point. Exit codes
  (`src/hooks/rewrite_cmd.rs`): 0 rewritten and auto-allowable, 1 no RTK
  equivalent, 2 a deny rule matched, 3 rewritten but an ask or no rule matched.
- The hook only sets `permissionDecision: "allow"` when RTK's own reading of
  Claude Code's permission rules finds an explicit allow rule
  (`src/hooks/permissions.rs`, "Precedence: Deny > Ask > Allow > Default
  (ask)"). Otherwise it emits `updatedInput` with **no** `permissionDecision`.
  Observed here:

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecisionReason": "RTK auto-rewrite",
      "updatedInput": { "command": "rtk git status", "description": "d" }
    }
  }
  ```

- Scope: "this only applies to Bash tool calls. Claude Code built-in tools such
  as `Read`, `Grep`, and `Glob` bypass the hook".
- Failure policy: "Hooks must **never block command execution**. All error
  paths (missing binary, bad JSON, rewrite failure) must exit 0 so the agent's
  command runs unmodified." (`hooks/README.md`)

### How `rtk grep` is implemented

`src/cmds/system/search.rs`, "Shared search-output filter for `rtk grep` and
`rtk rg`":

- "Runs the agent's exact engine (grep or rg) — never substituting one for the
  other — and compresses its output by grouping matches by file, capping, and
  teeing overflow."
- It shells out (`resolved_command("grep")` / `resolved_command("rg")`). It
  does not use the `ignore` crate.
- Flags it adds as parse aids: grep gets `-n -H -I --null`; rg gets
  `-n --with-filename --null`. Note `-I` makes grep skip binary files, which
  plain `grep` would report as "Binary file matches".
- Calls with format flags (`-c`, `-l`, `-o`, ...), no pattern, or output it
  cannot parse are passed through verbatim.
- Caps come from `[limits]`: 200 results total, 25 per file.
- History: older releases did run ripgrep behind `rtk grep`. The changelog
  entry "**grep:** run the invoked engine instead of substituting rg for grep"
  sits in the 0.43.0 section (2026-06-28).

So in 0.45.0 `rtk grep` does **not** skip gitignored files. Verified:
`rtk grep -r NEEDLE_XYZ .` returns both `./src/a.txt` and the gitignored,
hidden `./.claude/notes.md`; `rtk rg NEEDLE_XYZ .` returns only `./src/a.txt`
because that is what `rg` itself does. There is no RTK-level flag to change
ignoring for either; use the engine's own flags (`rtk rg -uu ...`).

### How `rtk find` is implemented

`src/cmds/system/find_cmd.rs` is a reimplementation, not a wrapper:

- It walks with `ignore::WalkBuilder` and sets `.hidden(!search_hidden)`,
  `.git_ignore(true)`, `.git_global(true)`, `.git_exclude(true)`.
  `search_hidden` is true only when the name pattern itself starts with a dot.
- That is why it skips gitignored and hidden paths where real `find` would
  list them. Verified: `rtk find . -name '*.md'` prints nothing in the
  experiment repo while `/usr/bin/find . -name notes.md` prints
  `./.claude/notes.md`.
- **No flag disables this.** `rtk find --help` offers only `--ultra-compact`
  and `--skip-env`, and the source parses only `-name`, `-iname`, `-type`,
  `-maxdepth` plus RTK's own `-m/--max` and `-t/--file-type`.
- Because the builder leaves `.ignore` support at its default (on), the
  `.ignore` whitelist from section 3 also works here: with `!.claude/` in
  `.ignore`, `rtk find . -name '*.md'` returns `.claude/notes.md` (verified).
- Unsupported native syntax is rejected, not delegated. The list includes
  `-not`, `!`, `-o`, `-a`, `-exec`, `-execdir`, `-delete`, `-print0`,
  `-newer`, `-perm`, `-size`, `-mtime`, `-empty`, `-regex`; rtk then fails
  with "rtk find does not support compound predicates or actions (e.g. -not,
  -exec). Use `find` directly."
- The hook still rewrites those commands: `rtk rewrite 'find . -name x -newer
  y'` prints `rtk find . -name x -newer y`, which then exits 1 with the message
  above (verified). Escape hatches that are left alone by the rewriter
  (verified with `rtk rewrite`): `RTK_DISABLED=1 find ...`, `rtk proxy find
  ...`, and an absolute path such as `/usr/bin/find ...`.
- Results are capped at 50 by default (`max_results: 50`).

### How "tokens saved" is computed

- Estimator: `estimate_tokens` in `src/core/tracking.rs` is
  `(text.len() as f64 / 4.0).ceil()`, i.e. bytes divided by four. "RTK ships
  **no real tokenizer** by design."
- Formula (`docs/guide/analytics/gain.md`): Input Tokens =
  `estimate_tokens(raw_command_output)`, Output Tokens =
  `estimate_tokens(rtk_filtered_output)`, Saved = Input − Output, Savings % =
  Saved / Input × 100.
- "Input" and "output" here are **not** model input/output tokens. Both are
  sizes of one command's stdout, before and after filtering.
- What the raw baseline is depends on the command. For `rtk grep` it is the
  stdout of the engine run with RTK's parse flags. For `rtk find` it is RTK's
  own newline-joined result list (`files.join("\n")`), which is already
  gitignore- and hidden-filtered, so it is not what `find` would have printed.
- Passthrough commands are recorded with zero input and zero output tokens so
  they "won't dilute savings statistics" (`track_passthrough`).
- Reading the number: "The percentage is reliable. ... The absolute token
  counts are approximate. They will not match your provider's billing." And
  "A command showing 90% fewer output bytes does not make your session 90%
  cheaper" (`docs/guide/resources/savings-explained.md`).
- Storage: local SQLite, `~/.local/share/rtk/history.db`, 90-day retention.

### What the hook does not rewrite

The assumption "pipelines and compound commands are never rewritten" is out of
date for 0.45.0. From `hooks/README.md`, "Compound Command Handling", and
`rtk rewrite` runs on this machine:

| Input                                | Result                      |
| ------------------------------------ | --------------------------- |
| `ls -la; git diff`                   | `rtk ls -la; rtk git diff`  |
| `cd /tmp && git status`              | `cd /tmp && rtk git status` |
| `git log \| grep fix`                | `git log \| rtk grep fix`   |
| `grep -r foo . \| head -5`           | not rewritten               |
| `find . -name "*.md" \| xargs wc -l` | not rewritten               |
| `git log \|& grep x`                 | not rewritten               |
| `git status > out.txt`               | not rewritten               |
| `git status 2>&1`                    | `rtk git status 2>&1`       |
| `echo $(git status)`                 | not rewritten               |
| `for f in *; do git status; done`    | not rewritten               |
| `htop`, `fd -e md`, `man rg`         | not rewritten (no rule)     |
| `/usr/bin/grep -rn foo .`            | not rewritten               |
| `RTK_DISABLED=1 git status`          | not rewritten               |
| `sudo git status`                    | `sudo rtk git status`       |

Stated reasons:

- Pipes: "Producers and intermediate stages stay raw; only a pipeline-safe
  final stage is rewritten", and pipeline-safe rules are "Initially limited to
  argument-safe `grep`, `rg`, and `wc` invocations". Rewriting a producer would
  change the bytes the next stage parses.
- `|&`: "The complete pipeline stays raw".
- `&&`, `||`, `;`: "Both sides rewritten independently".
- Command/process substitution and redirects to a real file are "constructs the
  permission gate can't decompose, so they must never be auto-allowed"
  (`contains_unattestable_construct`, `src/discover/lexer.rs`); fd duplication
  like `2>&1` and `/dev/null` are exempt.
- Heredocs are skipped (`has_heredoc` in `hook_cmd.rs`).
- Lines inside a loop, conditional, case arm, function body or group are "not
  an independent command, so the whole block passes through untouched"
  (`registry.rs`).
- Unknown commands: "If a command isn't in the list above, RTK runs it through
  passthrough — the output reaches the LLM unchanged."

`rg foo | wc -l` came back unrewritten here even though `wc` is named as a
pipeline-safe final stage; the exact conditions were not traced in the source.

### `config.toml`

Location on Linux: `~/.config/rtk/config.toml`; `rtk config` prints the
effective values. Sections as defined in `src/core/config.rs`:

```toml
[tracking]
enabled = true
history_days = 90
# database_path = "/custom/path/history.db"

[display]
colors = true
emoji = true
max_width = 120

[filters]
ignore_dirs = [".git", "node_modules", "target", "__pycache__", ".venv", "vendor"]
ignore_files = ["*.lock", "*.min.js", "*.min.css"]

[tee]
enabled = true
mode = "failures"
max_files = 20
max_file_size = 1048576

[telemetry]
enabled = true

[hooks]
exclude_commands = []
transparent_prefixes = []

[limits]
grep_max_results = 200
grep_max_per_file = 25
status_max_files = 15
status_max_untracked = 10
passthrough_max_chars = 2000
```

- `[limits]`: caps on grep results (total and per file), on files shown by
  `git status` (staged/modified and untracked), and on characters kept when a
  parser falls back to passthrough.
- `[filters]`: documented as "These apply to file-reading commands (ls, find,
  grep, cat/rtk read). Paths matching these patterns are excluded from output".
  In the 0.45.0 source, `ignore_dirs` and `ignore_files` are referenced only in
  `src/core/config.rs`; no command reads them. Treat the section as inert in
  this version until shown otherwise.
- `[tee]`: "When a command fails, RTK saves the full unfiltered output so the
  LLM can read it without re-executing". `mode` is `"failures"` (default),
  `"always"` or `"never"`; `max_files` rotates; outputs under 500 bytes are not
  saved; files are truncated above 1 MB. Default directory
  `~/.local/share/rtk/tee/`, overridable with `directory` or `RTK_TEE_DIR`.
- `[hooks]`: `exclude_commands` lists commands never to auto-rewrite. It
  "Matches against the full command after stripping env prefixes", subcommand
  patterns work (`"git push"`), and "Patterns starting with `^` are treated as
  regex." `transparent_prefixes` lists literal wrapper prefixes (for example
  `docker exec mycontainer`) to strip before matching and re-prepend to the
  rewrite; it is in the source but not in the configuration guide.
- Environment: `RTK_DISABLED=1` (per command), `RTK_TEE_DIR`,
  `RTK_TELEMETRY_DISABLED=1`, `RTK_HOOK_AUDIT=1`; from the source also
  `RTK_NO_TOML=1` and `RTK_TOML_DEBUG=1`.

### TOML custom filters

Format (`src/filters/README.md`):

```toml
schema_version = 1

[filters.my-tool]
description = "Short description of what this filter does"
match_command = "^my-tool\\b"
strip_ansi = true
strip_lines_matching = ["^\\s*$", "^noise pattern"]
max_lines = 40
on_empty = "my-tool: ok"

[[tests.my-tool]]
name = "descriptive test name"
input = "raw command output here"
expected = "expected filtered output"
```

| Field                  | Meaning                                        |
| ---------------------- | ---------------------------------------------- |
| `match_command`        | Regex matched against the full command string  |
| `strip_ansi`           | Strip ANSI escapes first                       |
| `filter_stderr`        | Merge stderr into stdout before filtering      |
| `replace`              | Regex substitutions `{ pattern, replacement }` |
| `match_output`         | Short-circuit rules `{ pattern, message }`     |
| `strip_lines_matching` | Drop lines matching any regex                  |
| `keep_lines_matching`  | Keep only lines matching at least one regex    |
| `truncate_lines_at`    | Truncate lines longer than N characters        |
| `tail_lines`           | Keep only the last N lines                     |
| `max_lines`            | Keep only the first N lines                    |
| `on_empty`             | Message when nothing is left                   |

- Pipeline order: "strip_ansi → replace → match_output → strip/keep_lines →
  truncate → tail_lines → max_lines → on_empty".
- The struct in `src/core/toml_filter.rs` also has `head_lines`, which the
  README table does not list.
- "TOML filters strip noise lines — they don't reformat output."
- Lookup order, first match wins: `.rtk/filters.toml` (project), then
  `~/.config/rtk/filters.toml` (user), then the filters compiled into the
  binary, then passthrough. A project filter with a built-in's name shadows it
  with a warning.
- Trust: "custom filter files are **not applied until you trust them**. An
  untrusted (or edited) filter file is skipped silently". `rtk trust` lists
  each detected filter and asks; `--yes` skips the prompt; `rtk trust --list`
  shows trusted files; `rtk untrust` revokes. "Trust is recorded as a SHA-256
  of the file's contents, so editing a trusted file requires re-running
  `rtk trust`". The same gate now applies to the user-global file.
- Stated limit: "this is consent + tamper-evidence, not a sandbox."

## 5. grep and find background

Sources: POSIX.1-2024 (The Open Group Base Specifications Issue 8), XBD
chapter 9 <https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap09.html>,
`grep` <https://pubs.opengroup.org/onlinepubs/9799919799/utilities/grep.html>,
`find` <https://pubs.opengroup.org/onlinepubs/9799919799/utilities/find.html>;
GNU grep manual <https://www.gnu.org/software/grep/manual/grep.html>; Mike
Haertel, "why GNU grep is fast", freebsd-current, 2010-08-21
<https://lists.freebsd.org/pipermail/freebsd-current/2010-August/019310.html>;
`grep(1)`, `find(1)` and `fd(1)` as installed.

### BRE, ERE, and `-P`

- POSIX defines two dialects: 9.3 Basic Regular Expressions and 9.4 Extended
  Regular Expressions.
- Special characters. BRE: `.`, `[`, `\`, `*`, `^`, `$`. ERE adds `(`, `)`,
  `+`, `?`, `{`, `|`.
- Grouping and intervals are backslashed in BRE (`\(...\)`, `\{m,n\}`) and
  bare in ERE (`(...)`, `{m,n}`). Alternation exists only in ERE: "Two EREs
  separated by the special character `|` shall match a string that is matched
  by either."
- Back-references are a BRE feature in POSIX: "The back-reference expression
  `\n` shall match the same (possibly empty) string of characters". The ERE
  grammar has none (`BACKREF`: "Applicable only to basic regular expressions").
- `\?`, `\+`, `\|` in a BRE are implementation-defined in Issue 8. GNU grep
  implements them: "In basic regular expressions the meta-characters `?`, `+`,
  `{`, `|`, `(`, and `)` lose their special meaning; instead use the
  backslashed versions" (`grep(1)`).
- POSIX `grep` options are `-E`, `-F`, `-c`, `-e`, `-f`, `-i`, `-l`, `-n`,
  `-q`, `-s`, `-v`, `-x`. No `-r`, `-R` or `-P`: recursion and PCRE are
  extensions.
- GNU `-P`: "Interpret PATTERNS as Perl-compatible regular expressions
  (PCREs). This option is experimental when combined with the `-z`
  (`--null-data`) option, and `grep -P` may warn of unimplemented features."
- GNU accepts back-references in ERE too, which its manual lists as "well-
  defined in GNU grep but unspecified elsewhere". Verified locally:
  `grep -E '(abc)\1'` matches `abcabc`.

### Why GNU grep is fast

Haertel's post (he is the original author) gives two headline reasons:

- "GNU grep is fast because it AVOIDS LOOKING AT EVERY INPUT BYTE." It "uses
  the well-known Boyer-Moore algorithm, which looks first for the final letter
  of the target string", and "also unrolls the inner loop of Boyer-Moore".
- "GNU grep is fast because it EXECUTES VERY FEW INSTRUCTIONS FOR EACH BYTE
  that it _does_ look at."
- "Moreover, GNU grep AVOIDS BREAKING THE INPUT INTO LINES. Looking for
  newlines would slow grep down by a factor of several times". His summary:
  "Don't look for newlines in the input until after you've found a match."
- "GNU grep uses raw Unix input system calls and avoids copying data after
  reading it."
- Closing line: "The key to making programs fast is to make them do
  practically nothing."

The current manual's Performance section agrees on the algorithm and adds the
regex side: "When feasible, the Boyer–Moore fast string searching algorithm is
used to match a single fixed pattern", and "back-references cannot in general
be implemented via a finite state automaton, and instead trigger a
backtracking algorithm". It also notes grep "operates more efficiently in
single-byte locales".

One part of the 2010 post is historical: it recommends `--mmap`. The grep
installed here rejects it (`grep: unrecognized option '--mmap'`) and `grep(1)`
does not mention mmap.

### `grep -r` vs `-R`

`grep(1)`:

- `-r, --recursive`: "Read all files under each directory, recursively,
  following symbolic links only if they are on the command line. Note that if
  no file operand is given, grep searches the working directory."
- `-R, --dereference-recursive`: "Read all files under each directory,
  recursively. Follow all symbolic links, unlike `-r`."

Verified with a symlinked directory: `grep -rl` does not find the file behind
the link, `grep -Rl` does. ripgrep's default matches `-r` (links not followed;
`-L` to follow).

Neither option consults `.gitignore` or skips dotfiles. Binary files are
searched but, by default, output is suppressed after null bytes are found
(`--binary-files=binary`). Exclusions are explicit: `--exclude`,
`--exclude-dir`, `--include`.

### find's expression model

`find(1)`, EXPRESSION: everything after the starting points is an expression
made of

- **Tests**, which "return a true or false value, usually on the basis of some
  property of a file" (`-name`, `-type`, `-size`, `-perm`, `-newer`, ...).
- **Actions**, which "have side effects ... and return either true or false"
  (`-print`, `-exec`, `-delete`, `-printf`, ...).
- **Global options** (`-depth`, `-maxdepth`, ...) and **positional options**
  (`-regextype`, ...), which always return true.
- **Operators**, in decreasing precedence: `( expr )`, `! expr` / `-not`,
  `expr1 expr2` and `expr1 -a expr2` (AND), `expr1 -o expr2` (OR), and
  `expr1 , expr2` (list; both always evaluated).

Evaluation rules:

- Implicit AND: "Where an operator is missing, `-a` is assumed."
- Short-circuit, left to right: for AND "expr2 is not evaluated if expr1 is
  false"; for OR "expr2 is not evaluated if expr1 is true". POSIX specifies the
  same.
- Because actions are expressions too, their position matters: an action only
  runs when everything to its left on the same AND chain was true.
- Default action: "The `-print` action is performed on all files for which the
  whole expression is true, unless it contains an action other than `-prune`
  or `-quit`." POSIX words it as replacing the expression with
  `( given_expression ) -print`.
- Precedence trap documented in the man page: AND binds tighter than OR, so
  `find afile bfile -name afile -o -name bfile -print` "will never print
  afile".
- `-delete` "also acts like an option (since it implies `-depth`)".
- POSIX `find` has `-name`, `-iname`, `-path`, `-perm`, `-type`, `-links`,
  `-user`, `-group`, `-size`, `-atime`, `-ctime`, `-mtime`, `-exec`, `-ok`,
  `-print`, `-print0`, `-newer`, `-depth`, `-prune`, `-mount`/`-xdev` and a few
  more. `-delete`, `-maxdepth`, `-mindepth`, `-not`, `-and`, `-or` are GNU
  extensions.

### Why find does no ignoring

The model has no place for it. find evaluates one user-supplied expression
against every entry it reaches; it has no notion of a project or repository.
The installed `find(1)` contains no occurrence of "gitignore" and no
hidden-file option. Skipping anything is done with expressions the user
writes, such as `-name .git -prune -o ... -print` or `! -path '*/.git/*'`.
Verified: `/usr/bin/find . -name notes.md` lists the gitignored, hidden
`./.claude/notes.md`.

### What find can do that fd cannot express directly

Each row checked against `fd(1)` for 10.5.0.

| find                                    | fd 10.5.0                                                                                                                                        |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-perm MODE` (permission bits)          | No permission filter. Only `-t x` (executable).                                                                                                  |
| `-newer FILE` (compare to a file)       | No file reference. `--changed-within` / `--changed-before` (aliases `--newer`, `--older`) take a date or duration.                               |
| `-atime`, `-ctime`, `-amin`, `-cmin`    | None. fd filters on modification time only.                                                                                                      |
| `-links N`, `-inum N`, `-samefile F`    | None.                                                                                                                                            |
| `-o`, `!`, `( )` over arbitrary tests   | None. `--and` adds required patterns, `-E` excludes globs, repeated `-t` / `-e` are OR within the option. Name-level OR needs regex alternation. |
| `-delete`                               | No built-in action. README recommends `fd ... -X rm`.                                                                                            |
| `-printf FORMAT` (size, times, owner)   | `--format` has path placeholders only (`{}`, `{/}`, `{//}`, `{.}`, `{/.}`).                                                                      |
| `-ok`, `-execdir`                       | None. `-x` / `-X` only.                                                                                                                          |
| `expr1 , expr2` (two actions, one walk) | Multiple `-x` commands run for every result; no per-branch conditions.                                                                           |

What fd does cover, so a comparison should not overclaim: size (`-S`), type
(`-t`, including `e` for empty), owner (`-o user:group`), depth
(`-d`, `--min-depth`, `--exact-depth`), modification time, extension (`-e`),
`--prune`, `--one-file-system`, `-L`, and `-0`.

## Verified on this machine

All runs on 2026-10-11. `rtk proxy <cmd>` or an absolute path was used to
bypass the rewrite hook.

- `rg --version` → `ripgrep 15.2.0`, `features:+pcre2`, PCRE2 10.45 with JIT.
  `fd --version` → `fd 10.5.0`. `rtk --version` → `rtk 0.45.0`.
  `grep --version` → GNU grep 3.12. `find --version` → GNU findutils 4.11.0.
- Whitelist experiment (section 3 table), isolated `HOME`: `.ignore` works for
  rg and fd; `.rgignore` only rg; `.fdignore` only fd.
- `rg --no-config -l NEEDLE_XYZ` and `fd notes` with `.ignore` = `!.claude/` →
  both return `.claude/notes.md` without any hidden flag.
- `rg --no-config --hidden --debug` → prints the `whitelisting ./.claude` line
  naming `./.ignore`.
- `rg --no-config` with `-u`, `--hidden`, `--no-ignore`, `--no-ignore-vcs` →
  only `src/a.txt`; with `-uu`, `-uuu`, `--no-ignore-vcs --hidden` → also
  `.claude/notes.md`.
- `fd -t f` with no flag, `-I`, `--no-ignore-vcs` → only `src/a.txt`; with
  `-HI`, `-u`, `-H --no-ignore-vcs` → also `.claude/notes.md`; `-H` alone →
  not.
- Stock `rg --hidden --files` and stock `fd -H -t f` → 18 paths under `.git/`
  each. With `.git/` in a global fd ignore file → 0.
- fd precedence: `.fdignore` `.claude/` beats `.ignore` `!.claude/`; global fd
  ignore `src/` is undone by `!src/` in `.ignore` or `.gitignore`;
  `fd -H -E .claude` and `rg --hidden -g '!.claude/'` both beat the whitelist.
- Outside a git repo, `.gitignore` is not applied by rg or fd; with
  `--no-require-git` it is.
- `rg --no-config '(abc)\1'` → `error: backreferences are not supported`; with
  `-P` → matches `abcabc`.
- File containing a NUL: `rg hit dir` → no output, exit 1; `--binary` →
  `binary file matches (found "\0" byte around offset 3)`; `-a -c` → `1`.
- Config precedence: config `--smart-case`, `rg -c foo` → 2; adding
  `--case-sensitive` on the command line → 1; `--no-config` → 1.
- Symlinked directory: `rg -l` no match, `rg -L -l` match; `grep -rl` no match,
  `grep -Rl` match.
- GNU grep dialects: BRE `a+b` matches the literal `a+b`; `-E 'a+b'` matches
  `aab`; BRE `\(abc\)\1` and `-E '(abc)\1'` both match `abcabc`;
  `-P 'a(?=\+)'` matches `a+b`.
- `grep --mmap` → `unrecognized option '--mmap'`, exit 2.
- fd pattern mode: `fd text` and `fd Text` find `sub/Text.txt`, `fd TEXT`
  finds nothing; `fd 'sub/Text'` errors and points to `--full-path`;
  `fd -p 'sub/Text'` matches; `fd -g '*.txt'` matches by glob.
- `fd --help` mentions no config file and no default-flags variable.
- `rtk grep -r NEEDLE_XYZ .` → includes `./.claude/notes.md`;
  `rtk grep NEEDLE_XYZ .` → `grep: .: Is a directory` (real grep, no `-r`);
  `rtk rg NEEDLE_XYZ .` → only `./src/a.txt`.
- `rtk find . -name '*.md'` → nothing; with `.ignore` = `!.claude/` →
  `.claude/notes.md`; `/usr/bin/find . -name notes.md` →
  `./.claude/notes.md`.
- `rtk find . -name '*.md' -not -name x` → the "does not support compound
  predicates" error, exit 1.
- `rtk rewrite` on the commands in the section 4 table → results as listed.
- `printf '{"tool_name":"Bash","tool_input":{"command":"git status",...}}' |
  rtk hook claude` → `updatedInput` with `rtk git status` and no
  `permissionDecision`; `htop` and `grep -r foo . | head -5` → no output.
- `rtk config` → the sections and defaults shown in section 4 (telemetry is
  disabled on this machine).
- In the rtk 0.45.0 tree, `ignore_dirs` / `ignore_files` appear in no `.rs`
  file other than `src/core/config.rs`.

Not verified here: anything in section 1. Claude Code hook behaviour was taken
from the docs only; no test hooks were registered.

## Open questions / not specified by sources

- **Claude Code: do parallel hooks all receive the original input?** Implied
  by parallel execution, never stated as a sentence.
- **Claude Code: `updatedInput` without `permissionDecision`.** The docs
  describe it combined with `allow` or `ask` only. RTK relies on the
  undecided form when no allow rule matches.
- **Claude Code: `ask` from one hook plus `allow` + `updatedInput` from
  another.** Precedence says `ask` wins; whether the prompt then shows the
  rewritten input is not described.
- **Claude Code: `~` in `@` imports.** One example
  (`@~/.claude/my-project-instructions.md`), no rule. Whether `~/.claude` in an
  import follows `CLAUDE_CONFIG_DIR` is not addressed; read literally it would
  not.
- **Claude Code: relative import from `$CLAUDE_CONFIG_DIR/CLAUDE.md`.**
  Derived from two separate statements, not documented as a combination and
  not tested.
- **ripgrep literal optimisations.** The README names them; the mechanism
  (which literals are extracted, which SIMD routines) was not sourced. The
  author's blog and the `regex` / `memchr` crates are where to look.
- **ripgrep thread-count heuristic.** `rg(1)` says "heuristics" without
  numbers.
- **fd ignore precedence.** Not written in fd's README or man page. The order
  given here is the `ignore` crate's documented order plus fd's `walk.rs`
  wiring plus three experiments.
- **rtk `[filters]` section.** Documented as affecting ls/find/grep/read, but
  unreferenced in 0.45.0 source. Whether later releases wire it up was not
  checked.
- **rtk pipeline-safe `wc`.** `rg foo | wc -l` was not rewritten although `wc`
  is listed as pipeline-safe; conditions not traced.
- **rtk versions after 0.45.0.** v0.46.0 to v0.49.0 exist upstream and were
  not read.
- **GNU findutils Texinfo manual.** Not consulted; the find claims rest on
  `find(1)` 4.11.0 and POSIX.
- **GNU grep `--mmap` removal.** Only the local absence was checked, not the
  NEWS entry that removed it.
- **Fetched-quote wording.** POSIX, GNU grep manual and Haertel quotes came
  through an extracting fetch tool; re-read the pages before quoting them
  publicly.

### Sources

- Claude Code hooks reference — <https://code.claude.com/docs/en/hooks>
- Claude Code hooks guide — <https://code.claude.com/docs/en/hooks-guide>
- Claude Code memory / CLAUDE.md imports — <https://code.claude.com/docs/en/memory>
- Claude Code environment variables — <https://code.claude.com/docs/en/env-vars>
- Claude Code `.claude` directory — <https://code.claude.com/docs/en/claude-directory>
- ripgrep 15.2.0 (README, GUIDE, FAQ, `crates/ignore`, `crates/core`) — <https://github.com/BurntSushi/ripgrep/tree/15.2.0>
- fd v10.5.0 (README, `Cargo.toml`, `src/walk.rs`) — <https://github.com/sharkdp/fd/tree/v10.5.0>
- rtk v0.45.0 (README, `hooks/`, `docs/guide/`, `src/`) — <https://github.com/rtk-ai/rtk/tree/v0.45.0>
- POSIX.1-2024 Regular Expressions — <https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap09.html>
- POSIX.1-2024 `grep` — <https://pubs.opengroup.org/onlinepubs/9799919799/utilities/grep.html>
- POSIX.1-2024 `find` — <https://pubs.opengroup.org/onlinepubs/9799919799/utilities/find.html>
- GNU grep manual — <https://www.gnu.org/software/grep/manual/grep.html>
- Mike Haertel, "why GNU grep is fast" (2010-08-21) — <https://lists.freebsd.org/pipermail/freebsd-current/2010-August/019310.html>
- Local man pages: `rg(1)` 15.2.0, `fd(1)` 10.5.0, `grep(1)` 3.12, `find(1)` 4.11.0
