"""The work/break state machine. No sockets or OS calls, so it's easy to test."""

from __future__ import annotations

import time
from dataclasses import asdict, dataclass, replace

from .durations import format_duration

WORK, BREAK, LONG_BREAK = "work", "break", "long_break"
LABELS = {WORK: "Work", BREAK: "Break", LONG_BREAK: "Long break"}


@dataclass
class Settings:
    work: float = 30 * 60  # seconds
    rest: float = 10 * 60  # "break" is a Python keyword
    long_rest: float = 20 * 60
    long_every: int = 0  # long break every N work sessions, 0 = never
    cycles: int = 0  # stop after N work sessions, 0 = forever
    confirm: bool = False  # wait for a button click before each timer starts
    sound: bool = True


class Timer:
    def __init__(self, settings: Settings, notifier, clock=time.monotonic):
        self.settings = settings
        self.notifier = notifier
        self.clock = clock
        self.phase = WORK
        self.cycle = 1
        self.ends_at = 0.0
        self.paused_left: float | None = None
        self.pending: str | None = None  # next phase, waiting for a click
        self._dialog = None
        self.finished = False

    # -- lifecycle ---------------------------------------------------------

    def start(self) -> None:
        if self.settings.confirm:
            self._dialog = self.notifier.prompt(*self._prompt_text(WORK))
            if self._dialog is not None:
                self.pending = WORK
                return
        self._enter(WORK, announce=True)

    def tick(self) -> None:
        if self.finished or self.paused_left is not None:
            return
        if self.pending:
            if self._dialog is None or self._dialog.poll() is not None:
                self._advance(self.pending, announce=False)
            return
        if self.clock() >= self.ends_at:
            self._phase_done(confirm=self.settings.confirm)

    def close(self) -> None:
        self._close_dialog()

    # -- commands ----------------------------------------------------------

    def pause(self) -> str:
        if self.finished or self.pending:
            return "nothing to pause"
        if self.paused_left is not None:
            return "already paused"
        self.paused_left = self.remaining()
        return "paused"

    def resume(self) -> str:
        if self.paused_left is None:
            return "not paused"
        self.ends_at = self.clock() + self.paused_left
        self.paused_left = None
        return "resumed"

    def skip(self) -> str:
        if self.finished:
            return "already finished"
        if self.pending:
            self._advance(self.pending, announce=True)
        else:
            self._phase_done(confirm=False)
        return f"skipped to {LABELS[self.phase].lower()}"

    def update(self, **changes) -> str:
        """Change settings on the fly. If the current phase's length changes,
        the running timer is stretched or shrunk to match."""
        old = self.duration(self.phase)
        self.settings = replace(self.settings, **changes)
        delta = self.duration(self.phase) - old
        if self.paused_left is not None:
            self.paused_left = max(0.0, self.paused_left + delta)
        else:
            self.ends_at += delta
        return "updated"

    # -- queries -----------------------------------------------------------

    def duration(self, phase: str) -> float:
        s = self.settings
        return {WORK: s.work, BREAK: s.rest, LONG_BREAK: s.long_rest}[phase]

    def remaining(self) -> float:
        if self.paused_left is not None:
            return self.paused_left
        return max(0.0, self.ends_at - self.clock())

    def status(self) -> dict:
        return {
            "phase": self.phase,
            "remaining": self.remaining(),
            "paused": self.paused_left is not None,
            "pending": self.pending,
            "cycle": self.cycle,
            "finished": self.finished,
            "settings": asdict(self.settings),
        }

    # -- internals ---------------------------------------------------------

    def _next_phase(self) -> str:
        if self.phase != WORK:
            return WORK
        every = self.settings.long_every
        return LONG_BREAK if every and self.cycle % every == 0 else BREAK

    def _phase_done(self, confirm: bool) -> None:
        if self.phase == WORK and self.settings.cycles and self.cycle >= self.settings.cycles:
            self.finished = True
            self._sound()
            n = self.cycle
            self.notifier.notify("All done!", f"You finished {n} work session{'s' * (n != 1)}. Nice work.")
            return
        nxt = self._next_phase()
        self._sound()
        if confirm:
            self._dialog = self.notifier.prompt(*self._prompt_text(nxt))
            if self._dialog is not None:
                self.pending = nxt
                return
        self._advance(nxt, announce=True)

    def _advance(self, phase: str, announce: bool) -> None:
        if phase == WORK and self.phase != WORK:
            self.cycle += 1
        self._enter(phase, announce)

    def _enter(self, phase: str, announce: bool) -> None:
        self._close_dialog()
        self.phase = phase
        self.pending = None
        self.paused_left = None
        self.ends_at = self.clock() + self.duration(phase)
        if announce:
            self.notifier.notify(*self._notify_text(phase))

    def _notify_text(self, phase: str) -> tuple[str, str]:
        d = format_duration(self.duration(phase))
        if phase == WORK:
            return "Work time", f"Focus for {d}. Session {self._cycle_label()}."
        if phase == LONG_BREAK:
            return "Long break!", f"You've earned it. Step away for {d}."
        return "Break time!", f"Step away from the screen for {d}."

    def _prompt_text(self, phase: str) -> tuple[str, str, str]:
        d = format_duration(self.duration(phase))
        if phase == WORK and self.phase == WORK:  # very first session
            return "Take a break", f"Ready for {d} of work?", "Start Work"
        if phase == WORK:
            return "Break's over", f"Ready for {d} of work?", "Start Work"
        return "Work session done", f"Time for a {d} break.", "Start Break"

    def _cycle_label(self) -> str:
        n = self.cycle
        return f"{n}/{self.settings.cycles}" if self.settings.cycles else str(n)

    def _sound(self) -> None:
        if self.settings.sound:
            self.notifier.play_sound()

    def _close_dialog(self) -> None:
        if self._dialog is not None and self._dialog.poll() is None:
            self._dialog.terminate()
        self._dialog = None
