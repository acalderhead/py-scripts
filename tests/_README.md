# tests/

Optional tests for the scripts in `../scripts`, in the standard `pytest` layout.
Most one-off utilities will not need any; add them for anything with logic worth
protecting as the scripts and the library evolve.

`conftest.py` puts `../scripts` on `sys.path`, so a test imports a script by its
module name and calls its functions directly:

```python
import example_hello

def test_settings_defaults(tmp_path):
    s = example_hello.Settings(dir_base=tmp_path)
    assert s.name == "World"
```

## Running

A test needs `scriptkit` in the active interpreter, so run from one of the dev
venvs `setup-venvs.ps1` builds (the root README covers one-time setup):

```powershell
.\.venv313\Scripts\python.exe -m pytest -q
```

The VS Code Testing beaker works too; it is already wired in
`.vscode/settings.json`.
