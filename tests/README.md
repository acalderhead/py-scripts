# tests/

Optional tests for the scripts in `../scripts`. Standard `pytest` layout.

`conftest.py` adds `../scripts` to `sys.path`, so a test imports a script by its
module name and calls its functions directly:

```python
import example_hello

def test_settings_defaults(tmp_path):
    s = example_hello.Settings(dir_base=tmp_path)
    assert s.name == "World"
```

## Running

Tests need `scriptkit` available in the active interpreter. Use one of the dev
venvs from `setup-venvs.ps1` (see the root README for one-time setup), then:

```powershell
.\.venv313\Scripts\python.exe -m pytest -q
```

Or press the Testing beaker in VS Code (already wired in `.vscode/settings.json`).

Testing scripts is optional — many one-off utilities won't need it. Add tests
for anything with logic worth protecting as the library and scripts evolve.
