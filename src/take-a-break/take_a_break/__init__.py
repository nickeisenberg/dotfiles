"""Take a break: a background work/break timer controlled from the CLI."""

from __future__ import annotations

import os
from pathlib import Path

__version__ = "0.1.0"


def child_env() -> dict[str, str]:
    """Environment for ``python -m take_a_break ...`` child processes, so they
    find this package even when it isn't installed."""
    package_parent = str(Path(__file__).resolve().parent.parent)
    env = dict(os.environ)
    env["PYTHONPATH"] = os.pathsep.join(filter(None, [package_parent, env.get("PYTHONPATH")]))
    return env
