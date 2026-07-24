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
├── new-script.ps1     scaffolds a new pinned script from scriptkit's template
├── setup-venvs.ps1    builds the per-version dev venvs (.venv311/312/313)
├── ruff.toml          lint / format config
└── .vscode/           run / debug / test config
```

## One-time setup

Install uv:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Create the per-version dev virtualenvs (used by VS Code for IntelliSense,
linting, and debugging — one per supported Python minor version, each with
pinned `scriptkit[rich]` (RichLogger) plus dev tools installed):

```powershell
.\setup-venvs.ps1                 # builds .venv311 / .venv312 / .venv313
.\setup-venvs.ps1 -Tag v0.2.3     # pin a specific scriptkit into the venvs
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
> IntelliSense, linting, tests, and F5 debugging. They include the `[rich]`
> extra, so the Run button and F5 render RichLogger's decorated output. One
> consequence: the editor always has RichLogger available, so a script whose
> header does **not** pin `[rich]` still looks decorated in the editor but prints
> the plain `[TAG]` fallback under `uv run` — which remains the source of truth
> for what a script really does.

## Execution

### Authoring a new script

A "script" here is one file that already has all the plumbing — you only add its
inputs and its logic. `new-script.ps1` is what gives you that starting point: it
copies scriptkit's canonical template into `scripts/`, renames it, and pins its
`scriptkit` dependency, so the new file is a **runnable skeleton from the first
save**. From there the cycle is scaffold → edit → run → commit:

```powershell
.\new-script.ps1 my_tool          # 1. create scripts/my_tool.py (pinned, already runnable)
# 2. edit scripts/my_tool.py:
#      - add fields to Settings   -> each becomes a --flag and an APP_* env var
#      - write main()             -> what the tool actually does
uv run scripts/my_tool.py --help  # 3. run it; uv fetches the pinned scriptkit on first run
git add scripts/my_tool.py; git commit -m "add my_tool"; git push   # 4. save it
```

There's no project to build and no environment to manage per script — that four
step loop is the whole workflow.

### Running a script

Two ways; both honor the script's own `scriptkit` pin because both go through
`uv run`:

- **PowerShell:**
  ```powershell
  uv run scripts/<name>.py [args]
  uv run scripts/<name>.py --help          # lists every flag + its APP_* env var
  ```
- **VS Code:**
  - **Ctrl+Shift+B** → "uv run: current file (3.13)" runs the open script.
  - "uv run: current file (with args)" prompts for flags (e.g.
    `--name Aidan --times 2`).
  - **F5** debugs the open script. Unlike `uv run`, the debugger uses the
    selected **dev venv** (default `.venv313`), so it debugs against the
    `scriptkit` you installed with `setup-venvs.ps1`, not the script's pin.

### Decorated logs (RichLogger)

Whether output is decorated (colored, structured) or the plain `[TAG]` fallback
depends on where `rich_logger` is available:

- **Editor (Run button, F5, tests):** always RichLogger — the dev venvs install
  `scriptkit[rich]`.
- **`uv run`:** RichLogger only if the script's PEP 723 header pins the extra;
  otherwise the stdlib fallback. Add it per script when you want color:
  ```python
  # dependencies = [
  #   "scriptkit[rich] @ git+https://github.com/acalderhead/py-scriptkit.git@v0.2.3",
  # ]
  ```

**Write every log call as one pre-formatted string.** RichLogger's methods take a
single `message`, so pass an f-string — never extra positional or keyword
arguments:

```python
logger.stage(f"Greeting name={name} times={times}")   # works under both backends
logger.stage("Greeting", name=name, times=times)       # crashes under RichLogger
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
until you choose to move.** The repo currently defaults to **`v0.2.3`**. When a
newer tag ships and you want new scripts to use it:

1. **Bump the default pin** — the `-Tag` default in
   [`new-script.ps1`](new-script.ps1). New scripts scaffold against it
   automatically; this is the one source of truth for the default.
2. **Update this README's version references** to match — the pin in the
   RichLogger example above and the `setup-venvs.ps1 -Tag` example. (These docs
   are the only other place the version is written by hand.)
3. **Refresh the dev venvs** so the editor, lint, and tests reflect what new
   scripts will run:
   ```powershell
   .\setup-venvs.ps1 -Tag vX.Y.Z -Force
   ```
4. **Leave existing scripts on their current pins.** Each keeps the `scriptkit`
   it was written against on purpose; bump an individual script's header only
   when you want its newer behavior — then re-run and re-test that one script.

### Conventions

- **Shared logic that several scripts need belongs in `scriptkit`, not copied
  here.** If you find yourself pasting the same helper into a second script,
  that's the signal to promote it to the library (a new scriptkit release).
- **Keep secrets out of source and out of CLI arguments** (they leak into
  process lists, shell history, and logs); prefer environment variables
  (`APP_*`).
