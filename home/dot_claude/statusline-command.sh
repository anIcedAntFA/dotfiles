#!/usr/bin/env bash
# Claude Code status line
# Segments: cwd | branch | model [effort] | ctx X% | 5h: X% | 7d: X%

input=$(cat)

# jq with PATH fallback (GUI launches don't inherit shell PATH)
JQ=$(command -v jq || true)
for cand in /opt/homebrew/bin/jq /usr/local/bin/jq /usr/bin/jq; do
	[ -n "$JQ" ] && break
	[ -x "$cand" ] && JQ="$cand"
done
[ -z "$JQ" ] && {
	printf '%b\n' '\033[31mstatusline: jq not found\033[0m'
	exit 0
}

cwd=$(echo "$input" | "$JQ" -r '.cwd // empty')
model=$(echo "$input" | "$JQ" -r '.model.display_name // empty')
effort=$(echo "$input" | "$JQ" -r '.effort.level // empty')
remaining=$(echo "$input" | "$JQ" -r '.context_window.remaining_percentage // empty')
five_pct=$(echo "$input" | "$JQ" -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | "$JQ" -r '.rate_limits.seven_day.used_percentage // empty')

branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Shorten cwd starship-style: $HOME → ~, then keep only the last N segments
# (prefixed with …/). Override the count with CLAUDE_STATUSLINE_CWD_SEGMENTS.
short_cwd() {
	local p="$1" max="${CLAUDE_STATUSLINE_CWD_SEGMENTS:-3}"
	[ "$p" = "$HOME" ] && {
		printf '~'
		return
	}
	# SC2088: the ~ here is a literal display prefix, not a path to expand.
	# shellcheck disable=SC2088
	case "$p" in "$HOME"/*) p="~/${p#"$HOME"/}" ;; esac

	local IFS='/' seg parts=()
	for seg in $p; do [ -n "$seg" ] && parts+=("$seg"); done
	local n=${#parts[@]}
	if [ "$n" -le "$max" ]; then
		printf '%s' "$p"
	else
		local out="" i
		for ((i = n - max; i < n; i++)); do out="$out/${parts[i]}"; done
		printf '…%s' "$out"
	fi
}
cwd=$(short_cwd "$cwd")

dim='\033[2m'
bright='\033[1m'
yellow='\033[33m'
red='\033[31m'
green='\033[32m'
cyan='\033[36m'
reset='\033[0m'
sep="${dim} | ${reset}"

# Account indicator — driven by $CLAUDE_CONFIG_DIR, exported by the claude /
# claude-work fish wrappers (dotfiles docs/claude-code.md). Empty ⇒ personal.
case "${CLAUDE_CONFIG_DIR%/}" in
*/.claude.work)
	acct="work"
	acct_c="${red}"
	;;
*)
	acct="personal"
	acct_c="${green}"
	;;
esac

line="${bright}${acct_c}${acct}${reset}${sep}${dim}${cwd}${reset}"
[ -n "$branch" ] && line="${line}${sep}${bright}${cyan}${branch}${reset}"

if [ -n "$model" ]; then
	seg="${dim}${model}${reset}"
	[ -n "$effort" ] && [ "$effort" != "medium" ] && seg="${seg} ${dim}[${effort}]${reset}"
	line="${line}${sep}${seg}"
fi

if [ -n "$remaining" ]; then
	r=$(printf '%.0f' "$remaining")
	if [ "$r" -gt 80 ]; then
		c="${green}"
	elif [ "$r" -gt 70 ]; then
		c="${yellow}"
	else c="${red}"; fi
	line="${line}${sep}${c}ctx: ${r}%${reset}"
fi

if [ -n "$five_pct" ]; then
	u=$(printf '%.0f' "$five_pct")
	[ "$u" -ge 70 ] && c="${bright}${yellow}" || c="${dim}"
	line="${line}${sep}${c}5h: ${u}%${reset}"
fi

if [ -n "$week_pct" ]; then
	w=$(printf '%.0f' "$week_pct")
	[ "$w" -ge 70 ] && c="${bright}${yellow}" || c="${dim}"
	line="${line}${sep}${c}7d: ${w}%${reset}"
fi

printf '%b\n' "$line"
