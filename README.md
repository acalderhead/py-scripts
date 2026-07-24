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
linting, and debugging — one per supported Python minor version, each with the
pinned `scriptkit` installed):

```powershell
.\setup-venvs.ps1                 # builds .venv311 / .venv312 / .venv313
.\setup-venvs.ps1 -Tag v0.2.1     # pin a specific scriptkit into the venvs
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
> IntelliSense, linting, tests, and F5 debugging.

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

By default scripts use `scriptkit`'s stdlib logging fallback. For decorated
(colored, structured) console output, add the `[rich]` extra to the script's
pin:

```python
# dependencies = [
#   "scriptkit[rich] @ git+https://github.com/acalderhead/py-scriptkit.git@v0.2.1",
# ]
```

`uv run` then pulls RichLogger automatically. Without the extra, the same
`logger.stage(...)` / `logger.result(...)` calls still work — they just print
plain `[TAG]`-prefixed lines instead of color. *(Requires
`acalderhead/rich-logger` to be reachable at the pinned tag.)*

## Maintenance

- **Bump a script's `scriptkit` pin only when you want newer library behavior.**
  Each script keeps the version it was written against; there is no repo-wide
  upgrade. New scripts default to the tag baked into `new-script.ps1`.
- **Shared logic that several scripts need belongs in `scriptkit`, not copied
  here.** If you find yourself pasting the same helper into a second script,
  that's the signal to promote it to the library (a new scriptkit release).
- Keep secrets out of source and out of CLI arguments; prefer environment
  variables (`APP_*`).
