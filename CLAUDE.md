# CLAUDE.md — py-scripts

Session handoff for future Claude Code sessions. Read this first.

## What this is
A collection of **self-contained single-file scripts** under `scripts/`. Each
carries a PEP 723 header pinning [`scriptkit`](../py-scriptkit) at a released tag
and runs via `uv run` — the CLI, env wiring, path cascade, and logging all come
from scriptkit, so you write only `Settings` and `main()`. **This repo is NOT
versioned**; it points at py-scriptkit's current release (**v0.5.4**). Sibling
repo `py-scripts-cenvar` is the same shape — keep them consistent.

## Scaffolding (repo-root `.ps1` + double-click `.bat`)
- **`new-script.ps1` / `new-script.bat`** — new script into `scripts/`, pinned.
  No name → interactive; re-prompts on a name collision (no overwrite).
- **`new-test.ps1` / `new-test.bat`** — new pytest file. Interactive: pick an
  existing file to test (numbered), or a new name (warns `test_` is prepended);
  re-prompts on collision.
- Templates come from the sibling py-scriptkit checkout (GitHub-raw fallback at
  `-Tag`). `scriptkit new` (the CLI) scaffolds a **module**, not a script.
- **`.ps1`/`.bat` must be ASCII** (PS 5.1 parses them as cp1252); `eol=crlf` per
  `.gitattributes`. Instructions to the user must be **PowerShell** (`;` not
  `&&`, no `sed`).

## Running a script
- `uv run --exact scripts/<name>.py --help` (`--exact` keeps uv's cached env
  matched to the header — matters for the `[rich]` logging backend).
- VS Code: **Ctrl+Shift+B** = "uv run: current file (3.13)" (default build task);
  **F5** = header-aware debug through uv (`.vscode/debug/sitecustomize.py`); a
  **status-bar ▶ uv run button** via the *VSCode Task Buttons* extension
  (`spencerwmiles.vscode-task-buttons`, recommended in `.vscode/extensions.json`;
  config in `.vscode/settings.json`). The plain Python ▶ button can't be rebound
  to uv — use those instead. **VS Code must be opened at the repo root** for the
  tasks/button to resolve.

## Conventions & gotchas
- Output defaults **outside the repo**: `~/_repo-output/<script-name>` (the
  script template sets `dir_base`; scriptkit's `dir_output` == `dir_base`, no
  nested `output/`).
- Decorated RichLogger needs `scriptkit[rich]` in the header (git access);
  plain `scriptkit` falls back to a stdlib `[TAG]` logger and runs anywhere.
- A script's pin is **frozen on purpose** — bump it only to adopt new scriptkit
  behavior. README's "Adopting a new scriptkit release" is the reference.
- Dev venvs (`.venv311/312/313`) are for the editor only (IntelliSense, lint,
  tests); `uv run` ignores them and honors each script's own pin.
