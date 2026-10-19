# take-a-break

A work/break timer that runs in the background and pops up a desktop
notification when it's time to take a break and when it's time to get back to work.
Controlled entirely from the CLI. Pure Python, no dependencies, macOS + Linux
(not Windows: it relies on Unix sockets, `ps` and `fcntl`).

## Install

```sh
pip install -e .          # gives you the `tab` command
# or run without installing:
python3 -m take_a_break start
```

## Usage

```sh
tab start                 # 30 min work / 10 min break, repeating
tab start 25 5            # 25 min work / 5 min break
tab start -w 50m -b 10m -l 30m -e 3    # long 30m break after every 3rd session
tab start -n 4            # stop after 4 work sessions
tab start --confirm       # wait for a "Start Break" / "Start Work" click each time;
                          # after the click the window stays open as a live timer

tab                       # status (same as `tab status`)
tab status --watch        # live countdown
tab status --window       # reopen the timer window, then print the status
tab pause / tab resume
tab skip                  # end the current phase now
tab window                # open the timer window (closing it keeps the timer going)
tab set -b 15             # change settings while running (current timer adjusts)
tab stop

tab ps                    # list timer processes (shows stuck ones too)
tab kill [PID...]         # force-kill them
tab log                   # see what happened
```

Durations: a plain number is minutes, or use `90s`, `25m`, `1h30m`.
`--no-sound` turns off the chime. `tab start -f` runs in the foreground (handy for debugging).

## How it works

- `tab start` launches a detached background process. The CLI talks to it over a
  Unix socket at `~/.local/state/take-a-break/tab.sock` (log file is next to it).
- Notifications: `osascript` on macOS, `notify-send` on Linux.
- Timer window: tkinter (ships with most Pythons; Homebrew needs `python-tk`,
  Debian/Ubuntu `python3-tk`). With `--confirm` it pops up with the
  Start button, then shows the countdown with Pause/Resume. Closing it during a
  prompt counts as clicking Start. Without tkinter (or a display), or if the
  window crashes, confirm uses
  `osascript` on macOS, `zenity` or `kdialog` on Linux; with none of those it
  falls back to auto-advancing.
- Sounds: `afplay` on macOS, `paplay`/`pw-play`/`aplay` on Linux.

### macOS note

Notifications sent through `osascript` appear as coming from **Script Editor**. If you don't
see them, enable notifications for Script Editor in *System Settings → Notifications*,
and check that Focus / Do Not Disturb is off.

## Tests

```sh
python3 -m unittest
```
