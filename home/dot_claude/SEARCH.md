# Search — `rg` for content, `fd` for files

Search with `rg` and `fd`, not `grep -r` or `find`. A guard hook refuses
recursive `grep` and `find` and points back here.

| Task                 | Run                                    |
| -------------------- | -------------------------------------- |
| Find text            | `rg PATTERN [PATH]`                    |
| Find a literal       | `rg -F 'a.b(c)' [PATH]`                |
| Find files by name   | `fd -H PATTERN [PATH]`                 |
| Find files by glob   | `fd -H -g '*.test.ts'`                 |
| List files of a kind | `fd -H -e md` · `rg --files -g '*.md'` |

`rg` patterns are Rust regex (no backreferences or lookaround unless `-P`).
`fd` patterns are regex matched against the file name; `-p` matches the full path.

Give `rg` a path (`.` will do) inside compound commands. With no path it reads
stdin whenever stdin is a pipe or a file, and then waits on it instead of
searching the directory.

## What a search does not see

Both tools skip files matched by `.gitignore` / `.ignore`, and `fd` also skips
dotfiles unless given `-H`. Nothing in the output says so. An empty result is
therefore "not seen", not "absent". Widen in this order:

1. `rg PATTERN` · `fd -H PATTERN`
2. No match, fewer than expected, or the target may sit in an ignored path (build
   output, `.env`, vendored code, tool state such as `.claude/`):
   `rg -uu PATTERN` · `fd -HI -E .git PATTERN`
3. Only when step 2 is empty may you say it does not exist. Before that, say
   "not found in non-ignored files".

Neither tool follows symlinks at any step. In a tree of symlinked directories
(installed skills, for one) add `-L`.

## When `grep` and `find` are still right

- Filtering a stream (`cmd | grep foo`) or one named file (`grep foo file.txt`).
- `git grep` — tracked files only, by design.
- Something `rg` / `fd` cannot express (`find -perm`, `-newer`, `-delete`, POSIX
  BRE semantics): prefix with `command`, e.g. `command find . -perm -u+x`. The
  guard lets that through.
