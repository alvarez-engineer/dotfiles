#!/usr/bin/env bash
# Claude Code status line. Reads the session JSON on stdin, prints one rich line:
#
#   ~/projects/dotfiles on main ● · Opus 4.8 · ▓▓▓▓▓▓▓░░░ 68% ctx · $0.42 · +156/-42 · 12m
#
# Deliberately painted with the 16 ANSI colors rather than muted-ink's hex codes.
# Ghostty and the VS Code integrated terminal both map those 16 slots to the
# muted-ink palette, so this line is themed in either host -- and stays legible in
# a terminal that has never heard of muted-ink. It is the same reasoning behind
# Claude Code's own `dark-ansi` theme, which claude/settings.json selects.
#
# Hardcoding #7aa2a5 here would look right in exactly two terminals and wrong
# everywhere else, and would need editing every time the palette moves.
#
# Segments after dir/branch/model are computed from the session JSON: the context
# bar sums the newest `message.usage` in transcript_path; cost/lines/duration come
# from the `cost` object. Every segment omits itself silently when its data is
# missing, so the line degrades to just dir+model and never fails the prompt.
#
# Glyphs are ASCII by default. A pipe cannot sniff the rendering font, and the
# bundled JetBrains Mono has no Nerd Font icons (they would render as tofu), so
# powerline glyphs are opt-in: export DOTFILES_STATUSLINE_GLYPHS=nerd.

set -uo pipefail # not -e: a status line must never fail the prompt

input="$(cat)"

rendered=""
if command -v python3 >/dev/null 2>&1; then
  # JSON in argv (stdin is already consumed); glyph choice in the environment.
  rendered="$(
    DOTFILES_STATUSLINE_GLYPHS="${DOTFILES_STATUSLINE_GLYPHS:-ascii}" \
    python3 -c '
import json, os, subprocess, sys

DIM="\033[90m"; RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"
BLUE="\033[34m"; MAGENTA="\033[35m"; CYAN="\033[36m"; RESET="\033[0m"

nerd = os.environ.get("DOTFILES_STATUSLINE_GLYPHS") == "nerd"
SEP    = "" if nerd else "·"      #  vs middot
BRANCH = " " if nerd else "on "        #  vs the word "on"
DIRTY  = "●"                            # filled dot
AHEAD  = "↑"; BEHIND = "↓"
BAR_F  = "▓"; BAR_E   = "░"        # dense vs light shade

try:
    d = json.loads(sys.argv[1])
except Exception:
    d = {}

w = d.get("workspace") or {}
m = d.get("model") or {}
cost = d.get("cost") or {}

home = os.path.expanduser("~")
cur = w.get("current_dir") or os.getcwd()
short = cur
if home and (cur == home or cur.startswith(home + "/")):
    short = "~" + cur[len(home):]

def git(*args):
    try:
        r = subprocess.run(["git", "-C", cur, *args],
                           capture_output=True, text=True, timeout=1)
        return r.stdout.strip()
    except Exception:
        return ""

# --- head: dir (+ git state) ---
head = CYAN + short + RESET

branch = git("rev-parse", "--abbrev-ref", "HEAD")
if branch == "HEAD":
    branch = git("rev-parse", "--short", "HEAD")
if branch:
    head += " " + DIM + BRANCH + RESET + YELLOW + branch + RESET
    if git("status", "--porcelain"):
        head += " " + RED + DIRTY + RESET
    counts = git("rev-list", "--left-right", "--count", "@{u}...HEAD")
    if counts:
        try:
            behind, ahead = (int(x) for x in counts.split())
            ab = (AHEAD + str(ahead) if ahead else "") + \
                 (BEHIND + str(behind) if behind else "")
            if ab:
                head += " " + DIM + ab + RESET
        except Exception:
            pass

# SEP-joined segments after the head.
segs = []

model = m.get("display_name") or ""
if model:
    segs.append(BLUE + model + RESET)

# --- context bar: newest message.usage in the transcript over the window ---
def context():
    tp = d.get("transcript_path")
    if not tp or not os.path.exists(tp):
        return None
    try:
        with open(tp, "rb") as f:
            f.seek(0, os.SEEK_END)
            if f.tell() > 200_000:
                f.seek(-200_000, os.SEEK_END)
            data = f.read()
    except Exception:
        return None
    for line in reversed(data.splitlines()):
        try:
            obj = json.loads(line)
        except Exception:
            continue
        msg = obj.get("message") if isinstance(obj, dict) else None
        u = msg.get("usage") if isinstance(msg, dict) else None
        if isinstance(u, dict):
            used = (u.get("input_tokens") or 0) \
                 + (u.get("cache_read_input_tokens") or 0) \
                 + (u.get("cache_creation_input_tokens") or 0)
            if used > 0:
                limit = 1_000_000 if d.get("exceeds_200k_tokens") else 200_000
                return used, limit
    return None

ctx = context()
if ctx:
    used, limit = ctx
    frac = min(used / limit, 1.0)
    color = GREEN if frac < 0.60 else (YELLOW if frac < 0.85 else RED)
    width = 10
    fill = int(round(frac * width))
    bar = color + BAR_F * fill + DIM + BAR_E * (width - fill) + RESET
    segs.append(bar + " " + color + str(int(round(frac * 100))) + "% ctx" + RESET)

tc = cost.get("total_cost_usd")
if isinstance(tc, (int, float)) and tc > 0:
    segs.append(MAGENTA + ("$%.2f" % tc) + RESET)

add = cost.get("total_lines_added") or 0
rem = cost.get("total_lines_removed") or 0
if add or rem:
    segs.append(GREEN + "+" + str(add) + RESET + "/" + RED + "-" + str(rem) + RESET)

dur = cost.get("total_duration_ms")
if isinstance(dur, (int, float)) and dur > 0:
    s = int(dur // 1000)
    h, r = divmod(s, 3600)
    mnt, sec = divmod(r, 60)
    ds = ("%dh%dm" % (h, mnt)) if h else ("%dm" % mnt if mnt else "%ds" % sec)
    segs.append(DIM + ds + RESET)

joiner = " " + DIM + SEP + RESET + " "
sys.stdout.write(head + (joiner + joiner.join(segs) if segs else ""))
' "$input" 2>/dev/null
  )"
fi

if [[ -n "$rendered" ]]; then
  printf '%s\n' "$rendered"
  exit 0
fi

# --- Fallback: no python3 (or it produced nothing). Dir/branch/model only, in the
# spirit of the original line -- still themed, still degrades to $PWD, never fails.
dim="\033[90m"; cyan="\033[36m"; yellow="\033[33m"; reset="\033[0m"

dir="$PWD"
short_dir="${dir/#$HOME/\~}"

branch=""
if command -v git >/dev/null 2>&1; then
  branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  [[ "$branch" == "HEAD" ]] && branch="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || true)"
fi

out="${cyan}${short_dir}${reset}"
[[ -n "$branch" ]] && out+=" ${dim}on${reset} ${yellow}${branch}${reset}"

printf '%b\n' "$out"
