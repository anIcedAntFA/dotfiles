function claude-work --description "Claude Code — force the work (Teams) account, any directory"
    # Explicit override for the auto-detecting `claude` function: always use the
    # work config dir (~/.claude.work — separate login, history, skills, no RTK
    # hook). See docs/claude-code.md.
    set -lx CLAUDE_CONFIG_DIR $HOME/.claude.work
    command claude $argv
end
