// Dotfiles Workbench — lay each project into one fixed shape:
//
//   ┌──────────┬─────────────────────┬───────────────┐
//   │          │  file / git diff    │               │
//   │ Explorer │─────────────────────│    claude     │
//   │ (sidebar)│  terminal (dir)     │  (dir-cc)     │
//   └──────────┴─────────────────────┴───────────────┘
//
// The two terminals are *editor-area* terminals, because VS Code's bottom panel
// is a single dock and cannot be both under-the-editor and a right column at
// once. Both launch vscode/bin/dev-shell, which hops out of the flatpak sandbox
// and attaches a tmux session; the right one asks for an independent session
// (`--suffix cc`) so it does not mirror the left. It is a ready shell by default
// -- set dotfilesWorkbench.claudeAutostart to run `claude` in it automatically.
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
// the only thing that survives a restore intact -- see layoutPresent().
const MANAGED = ["shell", "claude"];

function managedTerminals() {
  return vscode.window.terminals.filter((t) => MANAGED.includes(t.name));
}

// True once the layout exists. A restored window (enablePersistentSessions)
// revives the editor-area terminals itself, so this keeps auto-build from
// stacking a second set on top of them.
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
function layoutPresent() {
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
async function buildLayout({ replace = false } = {}) {
  const shell = shellPath();

  if (replace) for (const t of managedTerminals()) t.dispose();

  await vscode.commands.executeCommand("workbench.view.explorer");

  // Two columns; the left column split into two rows. Depth-first flattening
  // maps the groups to ViewColumns One/Two/Three:
  //   One  = center-top   (files, diffs)
  //   Two  = center-bottom (terminal)
  //   Three = right        (claude)
  // orientation 0 = horizontal (columns); nested groups alternate to rows.
  await vscode.commands.executeCommand("vscode.setEditorLayout", {
    orientation: 0,
    groups: [
      { groups: [{}, {}], size: 0.65 },
      { size: 0.35 },
    ],
  });

  vscode.window.createTerminal({
    name: "shell",
    shellPath: shell,
    location: { viewColumn: vscode.ViewColumn.Two },
  });

  const claudeArgs = ["--suffix", "cc"];
  if (config().get("claudeAutostart")) claudeArgs.push("--run", "claude");
  vscode.window.createTerminal({
    name: "claude",
    shellPath: shell,
    shellArgs: claudeArgs,
    location: { viewColumn: vscode.ViewColumn.Three },
  });

  // Land future file-opens in the top-left group, not on a terminal.
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

  if (
    config().get("autoLayout") &&
    vscode.workspace.workspaceFolders &&
    !layoutPresent()
  ) {
    // Let VS Code finish restoring its own state first; then build only if a
    // restore did not already put terminals in the editor area.
    setTimeout(() => {
      if (!layoutPresent()) buildLayout().catch(() => {});
    }, 800);
  }
}

function deactivate() {}

module.exports = { activate, deactivate };
