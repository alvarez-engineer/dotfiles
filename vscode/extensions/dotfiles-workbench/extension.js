// Dotfiles Workbench — lay each project into one fixed shape:
//
//   ┌──────────┬─────────────────────┬───────────────┐
//   │          │  file / git diff    │               │
//   │ Explorer │─────────────────────│    claude     │
//   │ (sidebar)│  shell              │               │
//   └──────────┴─────────────────────┴───────────────┘
//        one tmux session (<dir>), two windows: shell + claude
//
// The two terminals are *editor-area* terminals, because VS Code's bottom panel
// is a single dock and cannot be both under-the-editor and a right column at
// once. Both launch vscode/bin/dev-shell, which hops out of the flatpak sandbox
// and attaches the project's tmux session -- each as a named *window* of that
// one session (`--window shell` / `--window claude`), not as separate sessions.
// So `tmux attach -t <dir>` from Ghostty reaches both, while dev-shell's grouped
// attach keeps each terminal's current-window pointer its own.
//
// The claude window can start in a subdirectory (dotfilesWorkbench.claudeDir) and
// run a command on creation (dotfilesWorkbench.claudeAutostart + claudeCommand).
//
// Plain CommonJS, no build step — mirrors the repo's rule for the muted-ink
// theme. `node --check` in `make check` is the only gate it needs.

const vscode = require("vscode");
const os = require("os");
const path = require("path");

function config() {
  return vscode.workspace.getConfiguration("dotfilesWorkbench");
}

function shellPath() {
  const override = (config().get("shellPath") || "").trim();
  return override || path.join(os.homedir(), ".local", "bin", "dev-shell");
}

// The terminals this extension owns. Identity is the *name*, because that is
// the only thing that survives a restore intact -- see healLayout().
const MANAGED = ["shell", "claude"];

function managedTerminals() {
  return vscode.window.terminals.filter((t) => MANAGED.includes(t.name));
}

// True if *any* editor-area terminal of ours is present. Used only for the
// all-absent case, to tell "a fresh window that needs the whole layout built"
// from "a window whose managed terminals are all here but renamed by their
// shell" -- building on the latter would stack duplicates, the bug #18 fixed.
//
// Matching on creationOptions.location alone is not enough, and that was this
// extension's duplicate-layout bug. A terminal *we* create carries the
// `{ viewColumn }` object we passed. A *revived* one does not: a window reload
// restarts the extension host with an empty terminal list, so every restored
// terminal arrives through `$acceptTerminalOpened`, which rebuilds
// creationOptions from the persisted shellLaunchConfig as
// `{ name, shellPath, shellArgs, cwd, env, hideFromUser, ... }` -- with **no
// `location` key at all**. So `creationOptions.location` was undefined for
// exactly the terminals this check exists to find, the guard returned false,
// and every window open added a second `shell` and a second `claude` on top of
// the restored pair. `name` does survive that round-trip, so match on it first;
// keep the location test as a fallback for a terminal renamed by its shell.
function anyLayoutTerminal() {
  return vscode.window.terminals.some((t) => {
    if (MANAGED.includes(t.name)) return true;
    const loc = t.creationOptions && t.creationOptions.location;
    return !!loc && typeof loc === "object" && "viewColumn" in loc;
  });
}

// replace=true tears the managed terminals down first. Only the explicit
// Ctrl+Alt+D rebuild passes it: "rebuild" has to mean *replace*, or invoking it
// on a window that already has a layout stacks a second one -- the same way
// installing or reloading the extension into a live window used to. Disposing
// is safe because the tmux session lives on the host and outlives the terminal;
// a grouped clone is reaped by its own destroy-unattached, the base session and
// the shells in it survive, and the fresh terminal reattaches.
// Assert the two-column / three-group editor layout. Depth-first flattening
// maps the groups to ViewColumns One/Two/Three:
//   One  = center-top   (files, diffs)
//   Two  = center-bottom (shell terminal)
//   Three = right        (claude)
// orientation 0 = horizontal (columns); nested groups alternate to rows.
// Idempotent: re-running it on the restored layout keeps three groups and each
// existing terminal in its group by index, so a survivor (claude in Three) is
// not dragged when we reassert the layout to heal a missing shell.
async function setEditorLayout() {
  await vscode.commands.executeCommand("workbench.view.explorer");
  await vscode.commands.executeCommand("vscode.setEditorLayout", {
    orientation: 0,
    groups: [
      { groups: [{}, {}], size: 0.65 },
      { size: 0.35 },
    ],
  });
}

// Create one managed terminal in its column. Both are named *windows of the one
// project session*, not separate sessions: they share a window list, so
// `tmux attach -t <dir>` from Ghostty reaches both and either can switch to the
// other's window, while dev-shell's grouped-session attach gives each its own
// current-window pointer so selecting a window never drags the other along.
function createManaged(name) {
  const shell = shellPath();
  if (name === "claude") {
    // The claude column can live in a subdirectory of the workspace -- open the
    // parent of several repos and still land this terminal in the one worked in.
    const claudeArgs = ["--window", "claude"];
    const claudeDir = (config().get("claudeDir") || "").trim();
    if (claudeDir) claudeArgs.push("--dir", claudeDir);
    const claudeCommand = (config().get("claudeCommand") || "claude").trim();
    if (config().get("claudeAutostart")) claudeArgs.push("--run", claudeCommand);
    vscode.window.createTerminal({
      name: "claude",
      shellPath: shell,
      shellArgs: claudeArgs,
      location: { viewColumn: vscode.ViewColumn.Three },
    });
    return;
  }
  vscode.window.createTerminal({
    name: "shell",
    shellPath: shell,
    shellArgs: ["--window", "shell"],
    location: { viewColumn: vscode.ViewColumn.Two },
  });
}

async function buildLayout({ replace = false } = {}) {
  if (replace) for (const t of managedTerminals()) t.dispose();
  await setEditorLayout();
  createManaged("shell");
  createManaged("claude");
  // Land future file-opens in the top-left group, not on a terminal.
  await vscode.commands.executeCommand("workbench.action.focusFirstEditorGroup");
}

// Recreate only the managed terminals that are absent. A restore commonly
// brings back the long-lived claude window but not the shell -- the shell is a
// plain interactive shell, and VS Code does not revive a terminal whose process
// has exited (e.g. after the `code` shell function closes the terminal it was
// launched from). The old guard skipped the rebuild whenever *any* managed
// terminal was present, so a lone-survivor claude meant the shell was never
// restored. Heal the gap without disposing or duplicating the survivor.
async function healLayout() {
  const present = new Set(managedTerminals().map((t) => t.name));
  const missing = MANAGED.filter((n) => !present.has(n));
  if (missing.length === 0) return;

  if (missing.length === MANAGED.length) {
    // Nothing of ours by name. Build the full layout -- unless an unnamed
    // editor-area terminal already holds it (a managed terminal renamed by its
    // shell), which is the duplicate-stacking case the name guard exists for.
    if (!anyLayoutTerminal()) await buildLayout();
    return;
  }

  // Partial: reassert the layout so the recreated terminal lands in its column
  // (idempotent, does not move the survivor), then fill only the gaps.
  await setEditorLayout();
  for (const name of missing) createManaged(name);
  await vscode.commands.executeCommand("workbench.action.focusFirstEditorGroup");
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand("dotfilesWorkbench.buildLayout", () =>
      buildLayout({ replace: true }).catch((e) =>
        vscode.window.showErrorMessage(`Dotfiles layout: ${e}`)
      )
    )
  );

  if (config().get("autoLayout") && vscode.workspace.workspaceFolders) {
    // Let VS Code finish restoring its own terminals first, then create only
    // what the restore did not bring back -- the whole layout on a fresh
    // window, or just the missing terminal(s) after a partial restore.
    setTimeout(() => {
      healLayout().catch(() => {});
    }, 800);
  }
}

function deactivate() {}

module.exports = { activate, deactivate };
