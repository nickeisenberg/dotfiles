"""Parsing and formatting of durations like ``25``, ``90s``, ``1h30m``."""

from __future__ import annotations

import re

_UNIT_SECONDS = {"h": 3600, "m": 60, "s": 1}
_NUMBER = r"\d+(?:\.\d+)?"
_NUMBER_RE = re.compile(_NUMBER)
_PART_RE = re.compile(rf"({_NUMBER})([hms])")


def parse_duration(text: str) -> float:
    """Return seconds. A bare number means minutes."""
    compact = str(text).strip().lower().replace(" ", "")
    # Not float(): it would also accept "nan", "inf", "1e3", "1_0".
    if _NUMBER_RE.fullmatch(compact):
        seconds = float(compact) * 60
    else:
        if not compact or _PART_RE.sub("", compact):
            raise ValueError(f"invalid duration {text!r} (try 25, 25m, 90s or 1h30m)")
        seconds = sum(float(n) * _UNIT_SECONDS[u] for n, u in _PART_RE.findall(compact))
    if seconds <= 0:
        raise ValueError(f"duration must be positive: {text!r}")
    return seconds


def format_duration(seconds: float) -> str:
    """e.g. ``1h30m``, ``25m``, ``45s``."""
    total = round(seconds)
    h, rem = divmod(total, 3600)
    m, s = divmod(rem, 60)
    parts = [f"{h}h"] if h else []
    if m:
        parts.append(f"{m}m")
    if s or not parts:
        parts.append(f"{s}s")
    return "".join(parts)


def format_clock(seconds: float) -> str:
    """Countdown, e.g. ``23:41`` or ``1:05:00``."""
    total = max(0, int(seconds + 0.999))
    h, rem = divmod(total, 3600)
    m, s = divmod(rem, 60)
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m:02d}:{s:02d}"
