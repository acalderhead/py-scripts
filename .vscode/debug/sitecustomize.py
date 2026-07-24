"""
debugpy bootstrap for header-aware debugging of PEP 723 scripts under `uv run`.

The "Debug current script — uv" launch config runs
`uv run --with debugpy --script <file>` with this folder on PYTHONPATH and
DEBUGPY_LISTEN set (see .vscode/tasks.json). Python imports this module at
interpreter startup, opens a debugpy listener inside the uv-resolved
environment — the one that honors the script's PEP 723 header, including the
`[rich]` extra — prints a readiness marker so VS Code knows to attach, then
waits for the editor to connect before the script runs.

Inert unless DEBUGPY_LISTEN is set, so it never affects a normal `uv run`.
"""

import os

# pop (not get) so the adapter subprocess debugpy spawns does not inherit
# DEBUGPY_LISTEN and re-enter this bootstrap — that recursion makes
# debugpy.listen() hang with "timed out waiting for adapter to connect".
_addr = os.environ.pop("DEBUGPY_LISTEN", None)
if _addr:
    import debugpy

    _host, _, _port = _addr.rpartition(":")
    debugpy.listen((_host, int(_port)))
    # VS Code's preLaunchTask watches for this line, then fires the attach.
    print("DEBUGPY_READY", flush=True)
    debugpy.wait_for_client()
