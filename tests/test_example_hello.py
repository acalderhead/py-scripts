"""
Sample test showing how to test a script in scripts/.

Import the script module (conftest.py puts scripts/ on sys.path), then exercise
its functions and Settings directly — no need to invoke the CLI.
"""

import example_hello


def test_settings_defaults(tmp_path):
    s = example_hello.Settings(dir_base=tmp_path)
    assert s.name == "World"
    assert s.times == 2
    # Inherited from scriptkit.ScriptSettings:
    assert s.dir_output == tmp_path / "output"


def test_main_returns_zero(tmp_path):
    s = example_hello.Settings(dir_base=tmp_path, name="Test", times=2)
    assert example_hello.main(s) == 0
