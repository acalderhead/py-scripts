# py-scripts

Personal Python utilities. Each script is a single self-contained file that pins its own [`scriptkit`](https://github.com/acalderhead/py-scriptkit) version and runs with [uv](https://docs.astral.sh/uv/).

## Setup (once)

Install uv:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

For editor IntelliSense/debugging, create a dev environment and select it in VS Code:

```powershell
uv venv
uv pip install "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@v0.2.1"
```

## The loop

```powershell
.\new-script.ps1 my_tool          # creates scripts/my_tool.py, pinned to a scriptkit release
# edit scripts/my_tool.py: add fields to Settings, write main()
uv run scripts/my_tool.py --help  # run it (uv fetches the pinned scriptkit)
git add scripts/my_tool.py; git commit -m "add my_tool"; git push
```

CLI flags, `APP_*` environment overrides, paths, and logging are inherited from
`scriptkit` — you write only `Settings` and `main()`.

## Running

- **VS Code:** open a script → `Ctrl+Shift+B` ("uv run: current file"). Use the
  "(with args)" task to pass flags, or F5 to debug (uses the dev `.venv`).
- **Terminal:** `uv run scripts/<name>.py [args]`.

## Layout

```
scripts/         the utilities (one file per tool)
tests/           optional pytest tests (see tests/README.md)
new-script.ps1   scaffolds a new pinned script into scripts/
.vscode/         run / debug / test config
```

## Notes

- Each script keeps the `scriptkit` version it was written against; bump the tag
  in a script's header only when you want newer library behavior.
- Shared logic that several scripts need belongs in `scriptkit`, not copied here.
