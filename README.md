# py-scripts

My personal Python utilities. Each script is self-contained and pins its own py-scriptkit version via a PEP 723 header (uv run).

## Requirements

- [uv](https://docs.astral.sh/uv/) — runs each script in an isolated env built
  from its pinned dependencies. Install (PowerShell):

  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

## Start a new script

From this repo's root:

```powershell
.\new-script.ps1 my_new_tool          # -> my_new_tool.py, pinned to scriptkit v0.1.0
.\new-script.ps1 my_tool -Tag v0.2.0  # pin a specific scriptkit release
```

That copies the canonical template from
[`py-scriptkit`](https://github.com/acalderhead/py-scriptkit), names it, and
pins the dependency. Then just edit the `Settings` fields and `main()` — the
CLI, env-var wiring, path cascade, and logging are all inherited.

**Day-to-day, this is all you do: run `new-script.ps1`, write your logic, commit.**

## Run a script

```powershell
uv run example_hello.py --name Aidan --times 2
uv run example_hello.py --help          # lists every flag + its env var
```

## How pinning works

Each script names the exact scriptkit version it was written against, so it
keeps running unchanged forever. Bump a script's pin (edit the tag in its
header) only when you want newer library behavior.
