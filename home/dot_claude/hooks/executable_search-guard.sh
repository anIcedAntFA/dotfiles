#!/usr/bin/env bash
# Claude Code PreToolUse guard hook (Bash matcher): refuse recursive `grep` and
# `find`, and say what to run instead. It never rewrites — the agent picks the
# replacement, so it knows which search visibility it is running at.
#
#   refused   grep -rn foo docs        find . -name '*.md'
#             rtk grep -rn foo docs    rtk find . -name x
#   allowed   cmd | grep foo           grep foo file.txt     git grep foo
#             command grep -r foo .    command find . -perm -u+x
#
# `command …` is the deliberate escape hatch for what rg/fd cannot express.
# Shared by both accounts (docs/claude-code.md), so it depends on jq only and
# fails open: any parse problem lets the command through.
#
#   echo '{"tool_input":{"command":"find . -name x"}}' | search-guard.sh

set -o errexit
set -o pipefail
set -o nounset

# shellcheck disable=SC2016 # backticks are literal Markdown in both messages
GREP_MSG='search-guard: recursive grep is refused. Use `rg PATTERN [PATH]` (`-F` literal, `-g GLOB`, `-t TYPE`). rg skips ignored files, so an empty result is "not seen", not "absent": retry with `rg -uu PATTERN` before concluding there is no match. If you need grep itself, run `command grep …`.'
# shellcheck disable=SC2016
FIND_MSG='search-guard: find is refused. Use `fd -H PATTERN [PATH]` (regex on the file name; `-g GLOB`, `-e EXT`, `-t f|d`, `-p` to match the full path). fd skips ignored files, so an empty result is "not seen", not "absent": retry with `fd -HI -E .git PATTERN` before concluding it does not exist. If fd cannot express it (-perm, -newer, -delete…), run `command find …`.'

command -v jq >/dev/null || exit 0
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

deny() {
	jq -n --arg reason "$1" '{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "deny",
			permissionDecisionReason: $reason
		}
	}'
	exit 0
}

# Judge one simple command, given as its words.
check() {
	# Drop leading VAR=value assignments, shell keywords and transparent wrappers.
	while (($#)); do
		case $1 in
		sudo | time | nohup | exec | env | if | then | else | elif | while | until | do | '!' | '{') shift ;;
		*=*) if [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then shift; else break; fi ;;
		*) break ;;
		esac
	done
	(($#)) || return 0

	local tool=$1 arg
	shift
	# `rtk grep` / `rtk find` typed by hand are judged as grep / find.
	if [ "$tool" = rtk ] && (($#)); then
		tool=$1
		shift
	fi

	case $tool in
	find) deny "$FIND_MSG" ;;
	grep | egrep | fgrep)
		for arg in "$@"; do
			case $arg in
			--) break ;;
			--recursive | --dereference-recursive) deny "$GREP_MSG" ;;
			--*) ;;
			-*[rR]*) deny "$GREP_MSG" ;;
			esac
		done
		;;
	esac
	return 0
}

# Split the command line into simple commands, honouring quotes, and check each.
words=()
word=""
have=0
quote=""

flush_word() {
	if ((have)); then words+=("$word"); fi
	word=""
	have=0
}

end_command() {
	flush_word
	check "${words[@]}"
	words=()
}

len=${#cmd}
for ((i = 0; i < len; i++)); do
	c=${cmd:i:1}
	if [ "$quote" = "'" ]; then
		if [ "$c" = "'" ]; then quote=""; else word+=$c; fi
		continue
	fi
	if [ "$quote" = '"' ]; then
		case $c in
		'"') quote="" ;;
		\\)
			i=$((i + 1))
			word+=${cmd:i:1}
			;;
		*) word+=$c ;;
		esac
		continue
	fi
	case $c in
	"'" | '"')
		quote=$c
		have=1
		;;
	\\)
		i=$((i + 1))
		word+=${cmd:i:1}
		have=1
		;;
	' ' | $'\t') flush_word ;;
	'#')
		if ((have)); then
			word+=$c
		else
			# Comment: skip to end of line.
			while ((i + 1 < len)) && [ "${cmd:i+1:1}" != $'\n' ]; do i=$((i + 1)); done
		fi
		;;
	'<')
		# A heredoc body is data, not commands — stop scanning.
		if [ "${cmd:i+1:1}" = '<' ] && [ "${cmd:i+2:1}" != '<' ]; then break; fi
		flush_word
		;;
	$'\n' | ';' | '&' | '|' | '(' | ')' | '`') end_command ;;
	*)
		word+=$c
		have=1
		;;
	esac
done
end_command
