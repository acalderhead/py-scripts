# py-scripts

Personal Python utilities, one self-contained file per tool. Each script pins its
own [`scriptkit`](https://github.com/acalderhead/py-scriptkit) tag in a PEP 723
header and runs under [uv](https://docs.astral.sh/uv/); the CLI, env-var wiring,
path cascade, and logging all come from scriptkit, so a script is just its
`Settings` and its `main()`.

Nothing here is installed, and nothing here is versioned. A script names a
scriptkit tag, `uv run` fetches exactly that tag on first run, and the script
keeps behaving the same long after the library moves on. Bumping scriptkit is a
per-script choice, never a repo-wide one.

The thing to understand before anything else: this repo runs code two different
ways and they do not agree. `uv run` reads a script's header and fetches the pin
it names, so a run always reflects the script's real dependencies. The dev
virtualenvs (`.venv311/312/313`) are a separate world that exists only for the
editor, for IntelliSense, linting, and tests. They carry plain `scriptkit` with
no `[rich]` extra, on purpose, so they never fake a dependency a script did not
ask for. The consequence is that everything venv-based (the plain Run button, the
stdlib debug configs, pytest) shows plain `[TAG]` logs, while everything uv-based
renders whatever the header pins. [Decorated logs](#decorated-logs-richlogger)
has the full matrix. It is the part of this repo that surprises people.

This repo tracks scriptkit **v1.0.0**. Running a script needs uv and nothing else.

| Section | What is in it |
| --- | --- |
| [Writing and running a script](#writing-and-running-a-script) | Scaffold a pinned script, fill in `Settings` and `main()`, run it from PowerShell or VS Code. Usually why you are here. |
| [Decorated logs](#decorated-logs-richlogger) | Why the same code logs two ways, the path-by-path matrix, and the `--exact` trap behind it. |
| [Adopting a new scriptkit release](#adopting-a-new-scriptkit-release) | The `-Tag` defaults to move, and why existing scripts stay put. |
| [Working in this repo](#working-in-this-repo) | The dev venvs, lint, tests, conventions, and layout. |

Every command block here is Windows PowerShell, and the syntax assumes it:
statements chain with `;`, not `&&`; paths are written `.\name`; and interpreters
are called as `python.exe`. Run them in a PowerShell terminal. VS Code's
integrated terminal is PowerShell by default on Windows, so the blocks paste in
unchanged; if its default profile has been switched to Git Bash or cmd, pick a
PowerShell profile from the terminal dropdown first, or the `.\`, `;`, and `.exe`
forms will not behave the same. The uv installer is the exception: it invokes
`powershell` itself, so it runs from any shell. A bare `.\*.ps1` can also trip the
execution policy on a fresh terminal, which is what the double-click `.bat`
launchers sidestep.


## Writing and running a script

You need uv once:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

A script here is one file that already has all the plumbing; you add its inputs
and its logic and nothing else. `new-script.ps1` writes that starting point: a
fresh copy of scriptkit's template into `scripts/`, named, with its `scriptkit`
pin already stamped, so the file runs from the first save. Double-click
`new-script.bat` for a prompt that re-asks on a name collision, or run the loop:

```powershell
.\new-script.ps1 my_tool                   # 1. create scripts/my_tool.py (pinned, runnable)
# 2. edit scripts/my_tool.py:
#      - add fields to Settings   -> each becomes a --flag and an APP_* env var
#      - write main()             -> what the tool actually does
uv run --exact scripts/my_tool.py --help   # 3. run it; uv fetches the pinned scriptkit on first run
git add scripts/my_tool.py; git commit -m "add my_tool"; git push   # 4. save it
```

The template comes from the sibling `py-scriptkit` checkout when it is present,
otherwise GitHub-raw at `-Tag`, and the new script is pinned to that tag. Run it
with no name, or double-click the `.bat`, for the interactive prompt.
`new-test.ps1` and `new-test.bat` scaffold a matching test: pick an existing
script by number, or name a new one.

`scriptkit new`, the cross-platform CLI in the scriptkit package, scaffolds an
importable module rather than a script. Reach for it when shared logic outgrows a
single file.

Once a script exists, both ways of running it go through `uv run`, so both honor
its pin:

- PowerShell:
  ```powershell
  uv run --exact scripts/<name>.py [args]
  uv run --exact scripts/<name>.py --help    # lists every flag and its APP_* env var
  ```
  `--exact` is not optional here; the [Decorated logs](#decorated-logs-richlogger)
  warning explains what it prevents.
- VS Code:
  - Ctrl+Shift+B runs "uv run: current file (3.13)" on the open script.
  - "uv run: current file (with args)" prompts for flags, e.g. `--name Aidan --times 2`.
  - F5 runs "Debug current script — uv (header-aware)", which debugs the script
    through uv, so it steps through the script's own pinned dependencies,
    RichLogger included when the header pins `[rich]`. A preLaunchTask starts it
    under debugpy and VS Code attaches; the mechanics are in
    [.vscode/debug/sitecustomize.py](.vscode/debug/sitecustomize.py).
  - The "Debug current script — venv 3.11/3.12/3.13 (stdlib)" configs are the
    fallback. They launch a dev venv directly, so they debug against the
    `scriptkit` from `setup-venvs.ps1` rather than the script's pin, and always
    log `[TAG]`. Use them if the uv attach misbehaves or the log style does not
    matter.


## Decorated logs (RichLogger)

The script's own PEP 723 header is the switch. Pin the `[rich]` extra and the
script logs through RichLogger, with color and aligned labels. Pin plain
`scriptkit` and the identical calls print through the stdlib `[TAG]` fallback.
Nothing else configures it, and the two forms are alternatives, not both:

```python
# dependencies = [                                                                  # decorated:
#   "scriptkit[rich] @ git+https://github.com/acalderhead/py-scriptkit.git@<tag>",
# ]
# dependencies = [                                                                  # [TAG] fallback:
#   "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@<tag>",
# ]
```

"The header decides" only holds on uv-based paths, because the dev venvs
deliberately carry plain `scriptkit`:

| Path | Honors `[rich]`? | Why |
| --- | --- | --- |
| `uv run --exact` (PowerShell) | yes | reads the header |
| Ctrl+Shift+B, "uv run: current file" | yes | wraps `uv run --exact` |
| F5, "Debug current script — uv" | yes | `uv run --exact --with debugpy` |
| F5, the "venv (stdlib)" configs, tests, IntelliSense | no, always `[TAG]` | dev venvs carry plain `scriptkit` |
| Plain Run button (Python extension) | no, always `[TAG]` | runs the selected interpreter, not uv |

The plain Run button is interpreter-based and cannot be redirected at the
workspace level, so reach for Ctrl+Shift+B when you want a run to reflect what the
script really does.

> Always pass `--exact` when running by hand. uv keeps one cached environment per
> script and, without `--exact`, only ever adds to it. Drop `[rich]` from a header
> and uv reuses the cached env that still holds `rich_logger`, so the script keeps
> printing decorated output it no longer asks for, silently, with no reinstall
> line to hint at it. `--refresh` does not fix this; it refreshes distributions,
> not environment membership. `--exact` prunes the env to exactly the header's
> dependencies, which is what makes `[rich]` authoritative in both directions.
> Every `uv run` task in [.vscode/tasks.json](.vscode/tasks.json) already passes it.

The vocabulary is aimed at what a script is doing, so a label names the call that
wrote the line:

| Purpose | Methods and labels |
| --- | --- |
| I/O and metadata | `read` `write` `metadata` |
| Flow and structure | `stage` `step` `substep` `info` |
| Config and results | `config` `metric` `result` |
| Warnings and alerts | `warning` `alert` |
| Errors | `error` |
| Developer checks | `check` `debug` |

Write every log call as a single pre-formatted string. RichLogger's methods take
one `message` argument, so pass an f-string and never extra positional or keyword
arguments:

```python
logger.stage(f"Greeting name={name} times={times}")   # works under both backends
logger.stage("Greeting", name=name, times=times)      # crashes under RichLogger
```

The stdlib fallback tolerates the second form, RichLogger does not, so the
single-string form is the portable one. RichLogger itself needs
`acalderhead/rich-logger` reachable at its pinned tag.


## Adopting a new scriptkit release

scriptkit is versioned on its own, and scripts pin a tag, so nothing here changes
until you decide to move. When a newer tag ships and you want new scripts on it:

1. Bump the default `-Tag` in the three scaffolders that carry one:
   [`new-script.ps1`](new-script.ps1) (what a new script pins),
   [`new-test.ps1`](new-test.ps1) (its GitHub-raw template fallback), and
   [`setup-venvs.ps1`](setup-venvs.ps1) (what the dev venvs install). Keep the
   three in step. `scriptkit new` is not in this list, because it scaffolds a
   module and a module carries no pin.

2. Update this README's two hand-written versions to match: the tracked version
   stated near the top, and the `setup-venvs.ps1 -Tag` example below. Those are
   the only places a version is written by hand here.

3. Refresh the dev venvs so the editor, lint, and tests reflect what new scripts
   will run. `-Force` matters, because without it an existing venv keeps packages
   a narrower pin no longer asks for:
   ```powershell
   .\setup-venvs.ps1 -Tag vX.Y.Z -Force
   ```

4. Leave existing scripts on their current pins. Each keeps the scriptkit it was
   written against on purpose; bump one script's header when you want its newer
   behavior, then re-run and re-test that script alone.

> Stale environments are the usual culprit when a script's logging or behavior
> does not match its header. Both caches only grow unless told otherwise: `uv run`
> needs `--exact` to prune its per-script env, and `setup-venvs.ps1` needs
> `-Force` to rebuild rather than top up. A version bump that widens an extra and
> then narrows it again, adding `[rich]` and later removing it, is exactly the
> case that leaves a stale `rich_logger` behind and makes a plain-pinned script
> look decorated.


## Working in this repo

The dev virtualenvs are for the editor, not for running scripts. Build them once:

```powershell
.\setup-venvs.ps1                 # builds .venv311 / .venv312 / .venv313
.\setup-venvs.ps1 -Tag v1.0.0     # pin a specific scriptkit into the venvs
.\setup-venvs.ps1 -Force          # delete and recreate them
```

Each venv carries plain pinned `scriptkit` plus the dev tools. VS Code defaults to
`.venv313`; switch with *Python: Select Interpreter* or the versioned debug
configs. When you first open the folder, check that `from scriptkit import ...`
resolves with no red squiggle. Every command below is also a task under
**Terminal > Run Task**.

### Lint

Ruff is configured in [`ruff.toml`](ruff.toml) for line length and rule set, and
runs from any dev venv. Lint does not depend on the interpreter, so `.venv313` is
enough:

```powershell
.\.venv313\Scripts\python.exe -m ruff check .          # report lint issues
.\.venv313\Scripts\python.exe -m ruff check --fix .    # apply the safe auto-fixes
.\.venv313\Scripts\python.exe -m ruff format .         # reformat in place
```

Tasks are `ruff check` and `ruff format`. Format-on-save is on for Python files,
set in [.vscode/settings.json](.vscode/settings.json), so day to day you mostly
save.

### Tests

Optional, and documented in [`tests/_README.md`](tests/_README.md). They live in
`tests/` and import each script by its module name. They need `scriptkit` and
`pytest`, both of which the dev venvs carry. On the default version:

```powershell
.\.venv313\Scripts\python.exe -m pytest -q
```

Across all three, the local stand-in for a CI matrix, since a script's pin allows
any of 3.11 through 3.13:

```powershell
.\.venv311\Scripts\python.exe -m pytest -q; .\.venv312\Scripts\python.exe -m pytest -q; .\.venv313\Scripts\python.exe -m pytest -q
```

`pytest (3.13)` is the default test task, with `pytest (3.12)`, `pytest (3.11)`,
and `pytest (all versions)` alongside it, or the VS Code Testing beaker.

### Conventions

Shared logic that more than one script needs belongs in `scriptkit`, not copied
here. The second time you paste the same helper, that is the signal to promote it
into a scriptkit release. Keep secrets out of source and out of CLI arguments,
where they leak into process lists, shell history, and logs; pass them through
environment variables (`APP_*`) instead.

### Layout

```
py-scripts/
├── scripts/                the utilities (one self-contained file per tool)
├── tests/                  optional pytest tests (see tests/_README.md)
├── new-script.ps1 / .bat   scaffold a new pinned script into scripts/
├── new-test.ps1 / .bat     scaffold a pytest file for a script
├── setup-venvs.ps1 / .bat  builds the per-version dev venvs (.venv311/312/313)
├── ruff.toml               lint config
├── CLAUDE.md               session handoff for Claude Code
└── .vscode/                run / debug / test config
    └── debug/              debugpy bootstrap for header-aware F5 (sitecustomize.py)
```
