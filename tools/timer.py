#! /usr/bin/python3

import argparse
import time
import sys
import json
import os
from pathlib import Path
import subprocess
import signal

# File to store the timer state
TIMER_STATE_FILE = Path("/tmp/timer_state.json")


def start_timer(seconds):
    """Start the timer and save its state."""
    # Record the start time and duration
    start_time = time.time()
    timer_state = {
        "start_time": start_time,
        "duration": seconds,
    }

    script = (
        f"import time, os; time.sleep({seconds}); "
        f"os.system(\"zenity --info --title='Timer Alert' --text='TIME IS UP!' --width=300 --height=200\")"
    )

    # Run the timer script as a background process
    process = subprocess.Popen(
        [sys.executable, "-c", script],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    # Save the process ID and state to the file
    timer_state["pid"] = process.pid
    with TIMER_STATE_FILE.open("w") as f:
        json.dump(timer_state, f)

    print(f"Timer started for {seconds} seconds.")
    print("You can check the timer progress by running the script with --check.")
    print("To stop the timer, use --kill.")


def check_timer():
    """Check the progress of the timer."""
    if not TIMER_STATE_FILE.exists():
        print("No active timer found.")
        sys.exit(1)

    # Load the timer state
    with TIMER_STATE_FILE.open("r") as f:
        timer_state = json.load(f)

    # Calculate remaining time
    start_time = timer_state["start_time"]
    duration = timer_state["duration"]
    elapsed = time.time() - start_time
    remaining = duration - elapsed

    if remaining <= 0:
        print("Timer has already ended.")
        TIMER_STATE_FILE.unlink()  # Clean up the state file
        sys.exit(0)

    # Format and display remaining time
    mins, secs = divmod(int(remaining), 60)
    hrs, mins = divmod(mins, 60)
    print(f"Time remaining: {hrs:02}:{mins:02}:{secs:02}")


def kill_timer():
    """Kill the active timer."""
    if not TIMER_STATE_FILE.exists():
        print("No active timer to kill.")
        sys.exit(1)

    # Load the timer state
    with TIMER_STATE_FILE.open("r") as f:
        timer_state = json.load(f)

    # Get the process ID
    pid = timer_state.get("pid")
    if not pid:
        print("No process ID found. Timer may have already ended.")
        TIMER_STATE_FILE.unlink()
        sys.exit(1)

    try:
        # Terminate the process
        os.kill(pid, signal.SIGTERM)
        print("Timer killed successfully.")
    except ProcessLookupError:
        print("Timer process not found. It may have already ended.")
    except Exception as e:
        print(f"Error killing timer: {e}")
    finally:
        # Clean up the state file
        TIMER_STATE_FILE.unlink()


def main():
    parser = argparse.ArgumentParser(description="Set a timer with desktop notifications.")
    parser.add_argument(
        "-s", "--seconds", type=int, default=0, help="Number of seconds for the timer."
    )
    parser.add_argument(
        "-m", "--minutes", type=int, default=0, help="Number of minutes for the timer."
    )
    parser.add_argument(
        "-hr", "--hours", type=int, default=0, help="Number of hours for the timer."
    )
    parser.add_argument(
        "-c", "--check",
        action="store_true",
        help="Check the remaining time for the current timer."
    )
    parser.add_argument(
        "-k", "--kill",
        action="store_true",
        help="Kill the active timer."
    )

    args = parser.parse_args()

    if args.check:
        check_timer()
    elif args.kill:
        kill_timer()
    else:
        # Calculate total seconds
        seconds = args.seconds + (args.minutes * 60) + (args.hours * 3600)

        # Validate input
        if seconds <= 0:
            print("Please specify a positive time duration for the timer.")
            sys.exit(1)

        start_timer(seconds)


if __name__ == "__main__":
    main()
