import unittest

from take_a_break.durations import format_clock, format_duration, parse_duration
from take_a_break.timer import BREAK, LONG_BREAK, WORK, Settings, Timer


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now


class FakeDialog:
    def __init__(self):
        self.clicked = False
        self.terminated = False

    def poll(self):
        return 0 if self.clicked or self.terminated else None

    def terminate(self):
        self.terminated = True


class FakeNotifier:
    def __init__(self, has_dialogs=True):
        self.notes, self.prompts, self.sounds = [], [], 0
        self.has_dialogs = has_dialogs
        self.dialog = None

    def notify(self, title, message):
        self.notes.append(title)

    def play_sound(self):
        self.sounds += 1

    def prompt(self, title, message, button):
        self.prompts.append(button)
        self.dialog = FakeDialog() if self.has_dialogs else None
        return self.dialog


def make(notifier=None, **settings):
    clock, notifier = FakeClock(), notifier or FakeNotifier()
    timer = Timer(Settings(**{"work": 60, "rest": 10, "long_rest": 30, **settings}), notifier, clock)
    timer.start()
    return timer, clock, notifier


def advance(timer, clock, seconds):
    clock.now += seconds
    timer.tick()


class TimerTests(unittest.TestCase):
    def test_work_break_cycle(self):
        timer, clock, notes = make()
        self.assertEqual((timer.phase, timer.cycle), (WORK, 1))
        advance(timer, clock, 59)
        self.assertEqual(timer.phase, WORK)
        advance(timer, clock, 1)
        self.assertEqual(timer.phase, BREAK)
        self.assertEqual(timer.remaining(), 10)
        advance(timer, clock, 10)
        self.assertEqual((timer.phase, timer.cycle), (WORK, 2))
        self.assertEqual(notes.notes, ["Work time", "Break time!", "Work time"])
        self.assertEqual(notes.sounds, 2)

    def test_long_break_every_n(self):
        timer, clock, _ = make(long_every=2)
        phases = []
        for _ in range(4):
            advance(timer, clock, timer.remaining())
            phases.append(timer.phase)
        self.assertEqual(phases, [BREAK, WORK, LONG_BREAK, WORK])

    def test_cycles_limit_finishes_after_last_work(self):
        timer, clock, notes = make(cycles=2)
        for _ in range(3):
            advance(timer, clock, timer.remaining())
        self.assertTrue(timer.finished)
        self.assertEqual(notes.notes[-1], "All done!")

    def test_pause_and_resume(self):
        timer, clock, _ = make()
        advance(timer, clock, 20)
        timer.pause()
        advance(timer, clock, 1000)
        self.assertEqual((timer.phase, timer.remaining()), (WORK, 40))
        timer.resume()
        advance(timer, clock, 40)
        self.assertEqual(timer.phase, BREAK)

    def test_skip(self):
        timer, clock, _ = make()
        timer.skip()
        self.assertEqual(timer.phase, BREAK)
        timer.skip()
        self.assertEqual((timer.phase, timer.cycle), (WORK, 2))

    def test_update_adjusts_running_phase(self):
        timer, clock, _ = make()
        advance(timer, clock, 20)
        timer.update(work=120)
        self.assertEqual(timer.remaining(), 100)
        timer.update(rest=99)  # other phase: no effect on current countdown
        self.assertEqual(timer.remaining(), 100)

    def test_confirm_waits_for_click_before_first_work(self):
        timer, clock, notes = make(confirm=True)
        self.assertEqual(timer.pending, WORK)
        advance(timer, clock, 500)  # nothing happens until the click
        self.assertEqual(timer.pending, WORK)
        notes.dialog.clicked = True
        timer.tick()
        self.assertEqual((timer.phase, timer.pending, timer.cycle, timer.remaining()), (WORK, None, 1, 60))
        self.assertEqual(notes.prompts, ["Start Work"])

    def test_confirm_waits_for_click(self):
        timer, clock, notes = make(confirm=True)
        notes.dialog.clicked = True
        timer.tick()
        advance(timer, clock, 60)
        self.assertEqual((timer.phase, timer.pending), (WORK, BREAK))
        advance(timer, clock, 500)  # nothing happens until the click
        self.assertEqual(timer.pending, BREAK)
        notes.dialog.clicked = True
        timer.tick()
        self.assertEqual((timer.phase, timer.pending, timer.remaining()), (BREAK, None, 10))
        self.assertEqual(notes.prompts, ["Start Work", "Start Break"])

    def test_confirm_without_dialog_tool_falls_back_to_auto(self):
        timer, clock, _ = make(FakeNotifier(has_dialogs=False), confirm=True)
        self.assertEqual((timer.phase, timer.pending), (WORK, None))
        advance(timer, clock, 60)
        self.assertEqual((timer.phase, timer.pending), (BREAK, None))


class DurationTests(unittest.TestCase):
    def test_parse(self):
        self.assertEqual(parse_duration("25"), 1500)
        self.assertEqual(parse_duration("25m"), 1500)
        self.assertEqual(parse_duration("90s"), 90)
        self.assertEqual(parse_duration("1h30m"), 5400)
        self.assertEqual(parse_duration("0.5"), 30)
        for bad in ("", "abc", "10x", "0", "-5", "5m abc"):
            with self.assertRaises(ValueError, msg=bad):
                parse_duration(bad)

    def test_format(self):
        self.assertEqual(format_duration(5400), "1h30m")
        self.assertEqual(format_duration(90), "1m30s")
        self.assertEqual(format_clock(1421), "23:41")
        self.assertEqual(format_clock(3900), "1:05:00")


if __name__ == "__main__":
    unittest.main()
