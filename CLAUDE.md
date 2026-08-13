# CLAUDE.md: py-scripts

Orientation for a new session. Read this first, then the README for how to run
scripts and adopt a release.

## The setup in one paragraph
A collection of self-contained single-file scripts under `scripts/`. Each carries a
PEP 723 header pinning `scriptkit` (the library in `../py-scriptkit`) at a released
tag and runs via `uv run`; the CLI, env wiring, path cascade, and logging all come
from scriptkit, so a script is just its `Settings` and its `main()`. This repo is
not versioned. It tracks scriptkit's current release, v1.0.0. The sibling
`py-scripts-cenvar` is the same shape; keep the two consistent.

## The model everything depends on
There are two environments and they do not agree. `uv run` reads a script's header
and fetches the exact pin it names, so a run reflects the script's real
dependencies. The dev virtualenvs (`.venv311/312/313`) are separate and exist only
for the editor: IntelliSense, lint, tests. They carry plain `scriptkit` with no
`[rich]`, on purpose. So every venv-based path (the plain Run button, the stdlib
debug configs, pytest) logs plain `[TAG]`, while every uv-based path logs whatever
the header pins. Most confusion in this repo traces back to which of the two is in
play.

## Common errors
- A script's logging does not match its header. Almost always a stale uv cache. uv
  keeps one env per script and, without `--exact`, only adds to it, so a dropped
  `[rich]` leaves `rich_logger` behind and the script keeps printing decorated
  output. `--refresh` does not fix it; `--exact` does, by pruning the env to the
  header. Always run with `--exact`.
- The dev venv is stale. `setup-venvs.ps1` tops up rather than rebuilds unless you
  pass `-Force`. After a pin change, `-Force`.
- A logger call crashes only under `[rich]`. RichLogger's semantic methods take one
  `message` string. `logger.stage("Greeting", name=name)` crashes under RichLogger,
  but the stdlib shim tolerates it, so it passes in a dev venv and fails at
  runtime. Write every call as one pre-formatted f-string:
  `logger.stage(f"Greeting name={name}")`.
- `[rich]` will not resolve. It fetches `rich_logger` from GitHub, so it needs git
  access. In CI or on an Azure box without it, pin plain `scriptkit` and take the
  `[TAG]` fallback.
- The tasks or the run button do not appear. VS Code must be opened at the repo
  root, or nothing in `.vscode` resolves.
- Output is missing from the repo. It is not there by design. A script's `dir_base`
  defaults to `~/_repo-output/<script-name>`, outside the repo, so runs never touch
  version control.
- The plain Run button always logs `[TAG]`. Not a bug. It is interpreter-based, not
  uv, and cannot be redirected at the workspace level. Use Ctrl+Shift+B to run
  through uv instead.

## Verify
Tests are optional (see [`tests/_README.md`](tests/_README.md)). When a script has
logic worth protecting, run from a dev venv:
```powershell
.\.venv313\Scripts\python.exe -m ruff check .
.\.venv313\Scripts\python.exe -m pytest -q
```

## Scaffolding and running
- `new-script.ps1` / `.bat` writes a new pinned script into `scripts/`. With no
  name it runs interactively and re-prompts on a collision rather than
  overwriting. `new-test.ps1` / `.bat` writes a matching pytest file, picking an
  existing script by number or naming a new one. Templates come from the sibling
  py-scriptkit checkout, GitHub-raw at `-Tag` as the fallback. `scriptkit new`, the
  cross-platform CLI, scaffolds a module, not a script.
- `uv run --exact scripts/<name>.py --help` lists every flag and its `APP_*` var.
  In VS Code, Ctrl+Shift+B runs the open file through uv (the default build task)
  and F5 debugs it through uv; a status-bar uv-run button comes from the VSCode
  Task Buttons extension (`spencerwmiles.vscode-task-buttons`).

## Invariants and scope
- A script's pin is frozen on purpose. Bump one header only to adopt newer
  scriptkit behavior, then re-run and re-test that script. The README's "Adopting a
  new scriptkit release" is the reference.
- `.ps1` and `.bat` files must be ASCII (PS 5.1 reads cp1252) and are `eol=crlf`.
  Instructions you hand the user are PowerShell: `;` not `&&`, no `sed`.
- The example scripts are slated for replacement; do not restyle them.
