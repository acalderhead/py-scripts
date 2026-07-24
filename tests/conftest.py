"""
Test configuration.

Scripts live in ../scripts as standalone files (not an installed package), so
add that folder to sys.path here. A test can then import a script by module
name, e.g. `import example_hello`. Importing runs the script's top level but
NOT main() — that's guarded by `if __name__ == "__main__"`.

Requires scriptkit in the active interpreter (the repo's .venv); each script
imports it at module load.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
