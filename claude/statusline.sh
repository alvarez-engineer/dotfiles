#!/usr/bin/env bash
# Claude Code status line. Reads the session JSON on stdin, prints one line.
#
# Deliberately painted with the 16 ANSI colors rather than muted-ink's hex codes.
# Ghostty and the VS Code integrated terminal both map those 16 slots to the
# muted-ink palette, so this line is themed in either host -- and stays legible in
# a terminal that has never heard of muted-ink. It is the same reasoning behind
# Claude Code's own `dark-ansi` theme, which claude/settings.json selects.
#
# Hardcoding #7aa2a5 here would look right in exactly two terminals and wrong
# everywhere else, and would need editing every time the palette moves.

set -uo pipefail # not -e: a status line must never fail the prompt

dim="\033[90m"   # bright black  -> muted-ink dim
cyan="\033[36m"  # cyan          -> muted-ink teal-ish
yellow="\033[33m"
blue="\033[34m"
reset="\033[0m"

input="$(cat)"

dir=""
model=""
if command -v python3 >/dev/null 2>&1; then
  # The JSON goes in argv, not stdin: stdin is already consumed, and a heredoc
  # script would collide with it.
  parsed="$(
    python3 -c '
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception:
    d = {}
w = d.get("workspace") or {}
m = d.get("model") or {}
print(w.get("current_dir") or "", m.get("display_name") or "", sep="\t")
' "$input" 2>/dev/null
  )"
  dir="${parsed%%$'\t'*}"
  model="${parsed#*$'\t'}"
fi

# Degrade to something true rather than printing nothing.
[[ -n "$dir" ]] || dir="$PWD"

short_dir="${dir/#$HOME/\~}"

branch=""
if command -v git >/dev/null 2>&1; then
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ "$branch" == "HEAD" ]] && branch="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || true)"
fi

out="${cyan}${short_dir}${reset}"
[[ -n "$branch" ]] && out+=" ${dim}on${reset} ${yellow}${branch}${reset}"
[[ -n "$model" ]] && out+=" ${dim}·${reset} ${blue}${model}${reset}"

printf '%b\n' "$out"
