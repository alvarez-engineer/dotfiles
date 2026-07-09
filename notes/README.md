# notes

Plain-text brain dumps, routed into standing lists by a marker grammar.

This module ships **tooling and conventions only**. Your notes live in
`$NOTES_DIR` (default `~/notes`), outside this repo — nothing private or
generated is tracked here.

## Layout

```
~/notes/
  inbox/2026-07-08T1432-hiring-loop.md      raw dumps
  todo.md  questions.md                     routed destinations
  remember.md  optimizations.md
  archive/2026-07/…                         dumps that have been routed
```

Make `~/notes` its own git repo if you want history and sync — `bdsplit --commit`
and `--push` work against whatever remote it has. Nothing here cares whether that
is GitHub, Bitbucket, or a bare repo on a NAS.

## Markers

Write freely. Mark the lines that should escape the dump, with at most three
leading spaces:

```markdown
Been going back and forth on the hiring loop. The take-home is too long and
nobody enjoys grading it.

[] email Dana about the Q3 numbers
?  do we actually need the staging cluster
!  Dana is out the last week of July
~  the Tuesday sync could have been this paragraph
```

| Marker       | Goes to            | Appended as             |
|--------------|--------------------|-------------------------|
| `[] text`    | `todo.md`          | `- [ ] text`            |
| `? text`     | `questions.md`     | `- text`                |
| `! text`     | `remember.md`      | `- text`                |
| `~ text`     | `optimizations.md` | `- text`                |

The todo marker also accepts `[ ]`, `- []` and `- [ ]` — the last is what
`todo.md` already contains and what an editor's checkbox support writes. All four
normalize to `- [ ] text` on the way out. `[]` is the one you type: it is three
keystrokes, it looks like the checkbox it becomes, and no line of prose begins
with it by accident.

`~` is for a dump that produced nothing: no todo, no question, nothing to
remember. Say so, and it routes like anything else. Without it the grammar would
quietly claim every dump must yield one of the other three — and a meeting that
generated no work is a fact worth accumulating. Read `optimizations.md` before
you accept the next recurring invite.

Not routed: `[x]` and `- [x]` (already done), anything inside a ``` or `~~~`
fence, anything in the leading `---` frontmatter block, and all unmarked prose —
that stays in the dump as the record of what you were thinking.

No marker is markdown syntax at line start, so nothing in ordinary prose is
scraped by accident — not a `-` bullet list, not a `+`/`-` pro-con list. If you
want to see the routing decisions before any file is touched, `bdsplit --dry-run`
prints every one of them.

Every routed line carries a relative backlink to its dump:

```markdown
- [ ] email Dana about the Q3 numbers
      <!-- archive/2026-07/2026-07-08T1432-hiring-loop.md -->
```

In nvim, `<localleader>t` / `q` / `r` / `o` prepend the four markers to the
current line, replacing one another rather than stacking.

## Commands

```bash
bd "hiring loop"              # new dump, opens $EDITOR
bd                            # new dump titled "dump"
echo "? why is CI slow" | bd -   # append to today's quick-capture dump

bdsplit --dry-run             # show what would be routed
bdsplit                       # route every dump in inbox/, archive each one
bdsplit inbox/2026-07-08T1432-hiring-loop.md   # just this one
bdsplit --commit              # ...and commit the result in $NOTES_DIR
bdsplit --push                # ...and push

bdf                           # fuzzy-open a note by filename    (needs fzf)
bdg staging                   # search note contents, open a hit (needs rg + fzf)
```

## Choosing the editor

`bd`, `bdf`, and `bdg` run `${EDITOR:-vi}`. Nothing here pins an editor, so set
it wherever you set the rest of your environment — `~/.bashrc.local` /
`~/.zshrc.local` if you use this repo's `shell` module, `~/.profile` otherwise:

```bash
export EDITOR="nvim"
export VISUAL="$EDITOR"          # some programs read VISUAL first
```

Prefix a single command to override it once: `EDITOR=nano bd "quick thought"`.

**A GUI editor needs its wait flag**, or it forks, exits immediately, and `bd`
returns before you have typed anything:

```bash
export EDITOR="code -w"          # VS Code
export EDITOR="cursor -w"        # Cursor -- broken on macOS, see below
export EDITOR="subl -w"          # Sublime Text
export EDITOR="zed -w"           # Zed
export EDITOR="gvim -f"          # gVim, -f for "foreground"
export VISUAL="$EDITOR"
```

`EDITOR` is split on whitespace, so `"code -w"` works but an editor path
containing spaces does not — put a wrapper script on `PATH` for that. This is the
same trade git makes. `cursor -w` is fine on Linux, but Cursor's `--wait` crashes
on macOS with `Unable to find helper app`; use `code -w` there. (`cursor` is the
GUI launcher — `cursor-agent` is a different binary and is not an editor.)

`bdg` opens the file *at the matching line*, and that syntax is not portable, so
it dispatches on the editor's name: `--goto file:N` for the VS Code family
(`code`, `code-insiders`, `codium`, `cursor`, `windsurf`), `file:N` for `subl`
and `zed`, and `+N file` for everything else. An unrecognized editor gets the
`+N` form, which is right for vi/vim/nvim/emacs/nano — and for `vi`, the fallback
when `EDITOR` is unset. If yours needs something different, `bdg --dry-run` shows
the exact command line without running it.

**Obsidian cannot be an `$EDITOR`.** It is a vault browser with no wait flag, and
its `obsidian://` URI only opens files already inside a registered vault. Point
`EDITOR` at a real editor and open `$NOTES_DIR` as a vault beside it — these are
plain markdown files in a plain directory, so both tools see the same notes with
no integration at all. Obsidian writes a `.obsidian/` directory into the vault
root; add it to `$NOTES_DIR/.gitignore` if you version your notes.

## Why it works this way

**Routing is the finalization signal.** A dump with markers is routed and moved
to `archive/<YYYY-MM>/`, filed under its own month rather than today's. A dump
with prose but no markers is left in `inbox/` — you are still writing it, and
`bdsplit` only ever looks at `inbox/`, so archiving an unfinished dump would put
it somewhere the router will never read again. Leave a note open on the side for
a week; nothing happens to it until you mark a line.

**Nothing is routed until you say so.** `bdsplit` is the commit, `bd` is the
capture. Routing on save would `mv` the dump out from under your open buffer;
routing when the editor exits would promote "I closed the window" into "I'm
done" — and would miss `bd -`, `bdf` and `bdg`, which is three of the four ways
a dump gets edited.

**An empty dump is archived, not parked.** `bd` writes the frontmatter template
*before* handing the file to `$EDITOR`, so `bd "test"` followed by `:q!` leaves a
dump nobody wrote. It has no markers, so it is never routed; it has no prose, so
leaving it in `inbox/` protects nothing. `bdsplit` archives it and says `empty:`.

**Archiving is what makes re-running safe.** Once a dump leaves `inbox/`, a bare
`bdsplit` cannot see it again, so nothing is ever double-routed. There is no
state file and no `routed:` stamp to get out of sync.

**Destinations are append-only.** `bdsplit` never rewrites `todo.md`. Check items
off, reorder them, delete them — it will not fight you.

The router is a fixed grammar matched with awk. It does not infer what a line
means. That is deliberate: it keeps this module inside the "config and thin shell
glue" budget the rest of the repo holds to. If it ever needs to get smart, it
should graduate to its own repo rather than grow here.
