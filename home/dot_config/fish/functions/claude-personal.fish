function claude-personal --description "Claude Code — force the personal account (default ~/.claude), even inside a work dir"
    # Explicit override: strip any inherited CLAUDE_CONFIG_DIR so Claude falls
    # back to the personal default ~/.claude. `env` runs the real binary (not
    # this shell's functions), so there is no recursion. See docs/claude-code.md.
    env -u CLAUDE_CONFIG_DIR claude $argv
end
