# notes

Plain-text brain dumps, routed into standing lists by a marker grammar.

This module ships **tooling and conventions only**. Your notes live in
`$NOTES_DIR` (default `~/notes`), outside this repo — nothing private or
generated is tracked here.

## Layout

```
~/notes/
  inbox/2026-07-08T1432-hiring-loop.md      raw dumps
  todo.md  questions.md  remember.md        routed destinations
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

- [ ] email Dana about the Q3 numbers
?     do we actually need the staging cluster
!     Dana is out the last week of July
```

| Marker       | Goes to        | Appended as             |
|--------------|----------------|-------------------------|
| `- [ ] text` | `todo.md`      | `- [ ] text` (verbatim) |
| `? text`     | `questions.md` | `- text`                |
| `! text`     | `remember.md`  | `- text`                |

Not routed: `- [x]` (already done), anything inside a ``` or `~~~` fence,
anything in the leading `---` frontmatter block, and all unmarked prose — that
stays in the dump as the record of what you were thinking.

Every routed line carries a relative backlink to its dump:

```markdown
- [ ] email Dana about the Q3 numbers
      <!-- archive/2026-07/2026-07-08T1432-hiring-loop.md -->
```

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

## Why it works this way

**Routing is the finalization signal.** A dump with no markers is left in
`inbox/` — you are still writing it. A dump with markers is routed and moved to
`archive/<YYYY-MM>/`, filed under its own month rather than today's.

**Archiving is what makes re-running safe.** Once a dump leaves `inbox/`, a bare
`bdsplit` cannot see it again, so nothing is ever double-routed. There is no
state file and no `routed:` stamp to get out of sync.

**Destinations are append-only.** `bdsplit` never rewrites `todo.md`. Check items
off, reorder them, delete them — it will not fight you.

The router is a fixed grammar matched with awk. It does not infer what a line
means. That is deliberate: it keeps this module inside the "config and thin shell
glue" budget the rest of the repo holds to. If it ever needs to get smart, it
should graduate to its own repo rather than grow here.
