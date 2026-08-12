# py-scripts

Personal Python utilities. Each script is a single self-contained file that pins
its own [`scriptkit`](https://github.com/acalderhead/py-scriptkit) version and
runs with [uv](https://docs.astral.sh/uv/) — the CLI, env-var wiring, path
cascade, and logging all come from `scriptkit`, so you write only `Settings` and
`main()`.

## File architecture

```
py-scripts/
├── scripts/           the utilities (one self-contained file per tool)
├── tests/             optional pytest tests (see tests/README.md)
├── new-script.ps1     (deprecated) local scaffolder — prefer `scriptkit new`
├── setup-venvs.ps1    builds the per-version dev venvs (.venv311/312/313)
├── ruff.toml          lint / format config
└── .vscode/           run / debug / test config
    └── debug/         debugpy bootstrap for header-aware F5 (sitecustomize.py)
```

## One-time setup

Install uv:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Create the per-version dev virtualenvs (used by VS Code for IntelliSense,
linting, and testing — one per supported Python minor version, each with plain
pinned `scriptkit` plus dev tools installed):

```powershell
.\setup-venvs.ps1                 # builds .venv311 / .venv312 / .venv313
.\setup-venvs.ps1 -Tag v0.4.0     # pin a specific scriptkit into the venvs
.\setup-venvs.ps1 -Force          # delete and recreate them
```

VS Code defaults to `.venv313`; switch with *Python: Select Interpreter* or the
versioned debug configs. When you first open the folder, confirm the
interpreter is set (`from scriptkit import ...` should resolve with no red
squiggle).

> **Two environments, on purpose.** `uv run` (used to actually run a script)
> ignores these venvs — it reads the `scriptkit` version the script pins in its
> own PEP 723 header and fetches exactly that, so a run always reflects the
> script's real dependencies. The dev venvs exist only for the editor:
> IntelliSense, linting, and tests. They carry **plain `scriptkit`** — no `[rich]`
> extra — deliberately, so they never fake a dependency a script didn't ask for.
> The trade-off is the reverse of what it used to be: venv-based paths (the ▶ Run
> button, the "venv (stdlib)" debug configs, pytest) always show the plain `[TAG]`
> fallback, while every uv-based path renders whatever the header pins. Run
> through uv — Ctrl+Shift+B or F5 — when you want to see a script's real logging.
> See [Decorated logs](#decorated-logs-richlogger) for the full matrix.

## Execution

### Authoring a new script

A "script" here is one file that already has all the plumbing — you only add its
inputs and its logic. `scriptkit new` gives you that starting point: it writes a
fresh copy of scriptkit's canonical template into `scripts/`, names it, and pins
its `scriptkit` dependency, so the new file is a **runnable skeleton from the
first save**. From there the cycle is scaffold → edit → run → commit:

```powershell
.\.venv313\Scripts\scriptkit.exe new my_tool   # 1. create scripts/my_tool.py (pinned, runnable)
# 2. edit scripts/my_tool.py:
#      - add fields to Settings   -> each becomes a --flag and an APP_* env var
#      - write main()             -> what the tool actually does
uv run --exact scripts/my_tool.py --help   # 3. run it; uv fetches the pinned scriptkit on first run
git add scripts/my_tool.py; git commit -m "add my_tool"; git push   # 4. save it
```

`scriptkit new` ships with `scriptkit`, so it's available from any dev venv that
has it installed (the `.venv313` above). With no local install, scaffold
straight from a tag:

```powershell
uvx --from "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@v0.5.0" scriptkit new my_tool
```

Either way it scaffolds into `scripts/` and pins the new script to the scriptkit
version it runs as (the dev venv's, or the `--from` tag). There's no project to
build and no environment to manage per script — that four-step loop is the whole
workflow.

> **`new-script.ps1` is deprecated.** The old Windows-only scaffolder still works
> this release but will be removed in the next one. Prefer `scriptkit new`, which
> does the same thing on any OS and needs no local checkout of py-scriptkit.

### Running a script

Two ways; both honor the script's own `scriptkit` pin because both go through
`uv run`:

- **PowerShell:**
  ```powershell
  uv run --exact scripts/<name>.py [args]
  uv run --exact scripts/<name>.py --help    # lists every flag + its APP_* env var
  ```
  `--exact` keeps uv's cached environment matched to the header — see the warning
  under [Decorated logs](#decorated-logs-richlogger) for why it matters.
- **VS Code:**
  - **Ctrl+Shift+B** → "uv run: current file (3.13)" runs the open script.
  - "uv run: current file (with args)" prompts for flags (e.g.
    `--name Aidan --times 2`).
  - **F5** → "Debug current script — uv (header-aware)" debugs the open script
    *through* uv, so it debugs the script's own pinned dependencies — including
    RichLogger when the header pins `[rich]`. A preLaunchTask starts it under
    debugpy and VS Code attaches; mechanics in
    [.vscode/debug/sitecustomize.py](.vscode/debug/sitecustomize.py).
  - The "venv 3.11/3.12/3.13 (stdlib)" configs are the fallback: they launch the
    dev venv directly, so they debug against the `scriptkit` from
    `setup-venvs.ps1` rather than the script's pin, and always log `[TAG]`.
    Use them if the uv attach misbehaves or the log style doesn't matter.

### Decorated logs (RichLogger)

**The script's own PEP 723 header is the switch.** Pin the `[rich]` extra and the
script logs through RichLogger (colored, aligned labels); pin plain `scriptkit`
and it logs through the stdlib `[TAG]` fallback. Nothing else configures this —
same header, same logging, on every uv-based path:

Pick one of these in the header — they're alternatives, not both:

```python
# dependencies = [                                                                  # decorated:
#   "scriptkit[rich] @ git+https://github.com/acalderhead/py-scriptkit.git@v0.5.0",
# ]
# dependencies = [                                                                  # [TAG] fallback:
#   "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@v0.5.0",
# ]
```

| Path | Honors `[rich]`? | Why |
| --- | --- | --- |
| `uv run --exact` (PowerShell) | yes | reads the header |
| **Ctrl+Shift+B** — "uv run: current file" | yes | wraps `uv run --exact` |
| **F5** — "Debug current script — uv" | yes | `uv run --exact --with debugpy` |
| F5 — "venv (stdlib)" configs, tests, IntelliSense | no — always `[TAG]` | dev venvs carry plain `scriptkit` |
| ▶ Run button (Python extension) | no — always `[TAG]` | runs the selected interpreter, not uv |

The dev venvs deliberately install plain `scriptkit`, so anything venv-based
shows the fallback regardless of the header. The ▶ Run button is interpreter-based
and cannot be redirected at the workspace level — **use Ctrl+Shift+B** when you
want the run to reflect what the script really does.

> **Always pass `--exact` when running by hand.** uv keeps one cached environment
> per script and, without `--exact`, only ever *adds* to it. Remove `[rich]` from a
> header and uv reuses the cached env that still contains `rich_logger`, so the
> script keeps printing decorated output it no longer asks for — silently, with no
> reinstall line to hint at it. (`--refresh` does **not** fix this; it refreshes
> distributions, not environment membership.) `--exact` prunes the env to exactly
> the header's dependencies, which is what makes `[rich]` authoritative in both
> directions. Every `uv run` task in [.vscode/tasks.json](.vscode/tasks.json)
> already passes it.

Labels match the method that emits them, so a log line names the call that wrote
it:

| Purpose | Methods → labels |
| --- | --- |
| I/O and metadata | `read` `write` `metadata` |
| Flow and structure | `stage` `step` `substep` `info` |
| Config and results | `config` `metric` `result` |
| Warnings and alerts | `warning` `alert` |
| Errors | `error` |
| Developer checks | `check` `debug` |

**Write every log call as one pre-formatted string.** RichLogger's methods take a
single `message`, so pass an f-string — never extra positional or keyword
arguments:

```python
logger.stage(f"Greeting name={name} times={times}")   # works under both backends
logger.stage("Greeting", name=name, times=times)      # crashes under RichLogger
```

The stdlib fallback tolerates the second form, but RichLogger does not, so the
single-string form is the portable one. *(RichLogger requires
`acalderhead/rich-logger` reachable at its pinned tag.)*

## Maintenance

All commands below assume the dev venvs from `setup-venvs.ps1` exist (ruff and
pytest are installed into each). Every one also has a VS Code task — run it from
**Terminal → Run Task** instead of typing the path if you prefer.

### Linting & formatting

Ruff is configured by [`ruff.toml`](ruff.toml) (line length, rule set) and runs
from any dev venv. From the repo root:

```powershell
.\.venv313\Scripts\python.exe -m ruff check .          # report lint issues
.\.venv313\Scripts\python.exe -m ruff check --fix .    # apply the safe auto-fixes
.\.venv313\Scripts\python.exe -m ruff format .         # reformat in place
```

Lint is Python-version-independent, so the default `.venv313` is enough — no
need to run it per version. Tasks: **`ruff check`**, **`ruff format`**.
Format-on-save is already enabled for Python files ([.vscode/settings.json](.vscode/settings.json)),
so day to day you mostly just save.

### Tests

Tests are optional (see [`tests/README.md`](tests/README.md)) and live in
`tests/`, importing each script by module name. They need `scriptkit` **and**
`pytest` — both are in the dev venvs. Run on the default version:

```powershell
.\.venv313\Scripts\python.exe -m pytest -q
```

Run on all three versions (the local equivalent of a CI matrix — a script's
PEP 723 pin allows any of 3.11–3.13, so tests should pass on all):

```powershell
.\.venv311\Scripts\python.exe -m pytest -q; .\.venv312\Scripts\python.exe -m pytest -q; .\.venv313\Scripts\python.exe -m pytest -q
```

Tasks: **`pytest (3.13)`** (default test task), **`pytest (3.11/3.12)`**,
**`pytest (all versions)`** — or the VS Code Testing beaker.

### Adopting a new `scriptkit` release

`scriptkit` is versioned on its own; scripts pin a tag, so **nothing here changes
until you choose to move.** The repo currently defaults to **`v0.4.0`**. When a
newer tag ships and you want new scripts to use it:

1. **Bump the default pin** — the `-Tag` default in
   [`setup-venvs.ps1`](setup-venvs.ps1). That drives both what the dev venvs
   install and what `scriptkit new` pins by default, since `scriptkit new` pins
   the version of scriptkit it runs as. *(The deprecated
   [`new-script.ps1`](new-script.ps1) carries its own `-Tag` default until it is
   removed next release.)*
2. **Update this README's version references** to match — the pins in the
   `[rich]` example above, the `setup-venvs.ps1 -Tag` and `uvx --from` examples,
   and the default stated just above. (These docs are the only other place a
   version is written by hand.)
3. **Refresh the dev venvs** so the editor, lint, and tests reflect what new
   scripts will run — `-Force` matters, because without it existing venvs keep
   packages a narrower pin no longer asks for:
   ```powershell
   .\setup-venvs.ps1 -Tag vX.Y.Z -Force
   ```
4. **Leave existing scripts on their current pins.** Each keeps the `scriptkit`
   it was written against on purpose; bump an individual script's header only
   when you want its newer behavior — then re-run and re-test that one script.

> **Stale environments are the usual culprit** when a script's logging or behavior
> doesn't match its header. Both caches only grow unless told otherwise: `uv run`
> needs `--exact` to prune its per-script env, and `setup-venvs.ps1` needs `-Force`
> to rebuild rather than top up. A version bump that widens then narrows an extra
> (adding `[rich]`, then removing it) is exactly the case that leaves a stale
> `rich_logger` behind and makes a plain-pinned script look decorated.

### Conventions

- **Shared logic that several scripts need belongs in `scriptkit`, not copied
  here.** If you find yourself pasting the same helper into a second script,
  that's the signal to promote it to the library (a new scriptkit release).
- **Keep secrets out of source and out of CLI arguments** (they leak into
  process lists, shell history, and logs); prefer environment variables
  (`APP_*`).
