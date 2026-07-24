#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "scriptkit @ git+https://github.com/acalderhead/py-scriptkit.git@v0.1.0",
# ]
# ///

"""
Purpose
───────
    Minimal working example of a scriptkit-based script: greets a name a chosen
    number of times, demonstrating the auto-CLI, env overrides, and logging.

Usage
─────
    uv run example_hello.py --name World --times 3
    APP_NAME=Cenvar uv run example_hello.py
"""

import sys
import traceback
from dataclasses import dataclass

from scriptkit import ScriptSettings, get_logger, parse_settings, set_log_level

__author__ = "Aidan Calderhead"
__version__ = "1.0.0"

logger = get_logger(__file__)


@dataclass(frozen=True)
class Settings(ScriptSettings):
    name: str = "World"
    times: int = 1


def main(settings: Settings) -> int:
    logger.stage("Greeting", name=settings.name, times=settings.times)
    for i in range(settings.times):
        logger.info(f"Hello, {settings.name}! ({i + 1}/{settings.times})")
    logger.result("Done")
    return 0


if __name__ == "__main__":
    settings = parse_settings(Settings, description=__doc__, version=__version__)
    set_log_level(logger, settings.log_level)
    try:
        sys.exit(main(settings))
    except Exception:
        logger.error(f"Pipeline failed:\n{traceback.format_exc()}")
        sys.exit(1)
