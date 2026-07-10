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

// True once the layout exists. A restored window (enablePersistentSessions)
// recreates the editor-area terminals itself, so this keeps auto-build from
// stacking a second set on top of them.
function layoutPresent() {
  return vscode.window.terminals.some((t) => {
    const loc = t.creationOptions && t.creationOptions.location;
    return loc && typeof loc === "object" && "viewColumn" in loc;
  });
}

async function buildLayout() {
  const shell = shellPath();

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
      buildLayout().catch((e) =>
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
