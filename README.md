# py-scripts

My personal Python utilities. Each script is self-contained and pins its own py-scriptkit version via a PEP 723 header (uv run).

---

## What this repo is

A growing archive of personal utility scripts. Every script is a **single,
standalone `.py` file** that declares its own dependencies in a PEP 723 header
and runs with [uv](https://docs.astral.sh/uv/). There is no shared package to
install and no build step — the common plumbing (CLI parsing, env overrides,
paths, logging) is inherited from
[`scriptkit`](https://github.com/acalderhead/py-scriptkit), which each script
pins to a specific released version.

This is the personal half of a three-repo system:

| Repo | Role |
| --- | --- |
| [py-scriptkit](https://github.com/acalderhead/py-scriptkit) | the library + template (source of truth) |
| **py-scripts** (this one) | personal scripts |
| [py-cenvar-scripts](https://github.com/acalderhead/py-cenvar-scripts) | Cenvar / work scripts |

## Layout

```
py-scripts/
├─ scripts/            the utilities (one standalone .py per tool)
│  └─ example_hello.py a minimal working example
├─ tests/             optional pytest tests for scripts (see tests/README.md)
├─ .vscode/           shared run/debug/test config
├─ new-script.ps1     scaffolds a new pinned script into scripts/
├─ ruff.toml          lint config
└─ .gitignore / .gitattributes
```

> **Why no `src/`?** `src/` is for an installable *package*. This repo is a
> *collection of standalone scripts*, so the standard fit is `scripts/` +
> `tests/`. The package layout lives in `py-scriptkit`, which actually is a
> package.

## Requirements

- **Python 3.11+**
- **[uv](https://docs.astral.sh/uv/)** — runs each script in an isolated env
  built from its pinned dependencies:

  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

## Daily workflow — this is the whole loop

```powershell
# 1. scaffold a new pinned script into scripts/
.\new-script.ps1 my_new_tool

# 2. edit scripts/my_new_tool.py — add fields to Settings, write main()

# 3. run it
uv run scripts/my_new_tool.py --help
uv run scripts/my_new_tool.py --some-flag value

# 4. commit
git add scripts/my_new_tool.py
git commit -m "add my_new_tool"
git push
```

Everything else — argument parsing, `APP_*` environment overrides, the
`dir_base → data/ output/` path cascade, and logging — comes from `scriptkit`.
You only ever write the `Settings` fields and `main()`.

### What `new-script.ps1` does

Copies the canonical template from `py-scriptkit` (the local sibling repo if you
have it cloned next door, otherwise from GitHub at the requested tag), drops it
into `scripts/` under a snake_case name, and pins its `scriptkit` dependency:

```powershell
.\new-script.ps1 reconcile_invoices          # -> scripts/reconcile_invoices.py @ v0.1.0
.\new-script.ps1 "Backup Photos" -Tag v0.2.0 # pin a specific scriptkit release
.\new-script.ps1 existing_tool -Force        # overwrite an existing file
```

## Running scripts

- **Terminal (canonical):** `uv run scripts/<name>.py`. uv reads the PEP 723
  header and builds an env with the exact pinned `scriptkit` — fully
  reproducible.
- **VS Code:** open a script and press **Ctrl+Shift+B** (the "uv run: current
  file" task). This is preferred over the ▶ Run button, because the Run button
  uses the selected interpreter and would only see `scriptkit` if it's installed
  there (see below).

## Editor setup (VS Code)

`.vscode/` is committed with shared settings, tasks, a debug config, and
recommended extensions (Python, Debugpy, Ruff). For IntelliSense, linting, and
**debugging**, create a one-time dev virtual environment that has `scriptkit`
installed, and point VS Code at it:

```powershell
uv venv
uv pip install "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@v0.1.0"
```

`.vscode/settings.json` already expects `.venv`. With it in place, the debugger
("Debug current script (.venv)") and the Testing beaker work. Running via
`uv run` remains the way to execute against a script's *exact* pin.

## Versioning & pinning

Each script names the `scriptkit` tag it was written against, so it keeps running
unchanged forever. To adopt newer library behavior, bump the tag in that script's
header (or re-scaffold with `-Tag`). See
[py-scriptkit's README](https://github.com/acalderhead/py-scriptkit#versioning--releasing--the-important-part)
for what the version numbers mean.

## Maintenance guidance

- **One tool = one file in `scripts/`.** Keep scripts self-contained; shared
  logic that more than one script needs belongs in `scriptkit`, not copied
  around.
- **Keep the PEP 723 header honest.** If a script needs another package (e.g.
  `requests`), add it to the header's `dependencies` list — that's what makes
  `uv run` reproducible.
- **Don't mass-bump pins.** Upgrade a script's `scriptkit` tag only when you have
  a reason to; the point of pinning is that old scripts stay stable.
- **Tests are optional** — add them under `tests/` for scripts with logic worth
  protecting (see `tests/README.md`).
