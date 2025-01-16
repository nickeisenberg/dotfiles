#! /usr/bin/python3

import argparse
import time
import sys
import json
from pathlib import Path
import subprocess

# File to store the timer state
TIMER_STATE_FILE = Path("/tmp/timer_state.json")


def start_timer(seconds):
    """Start the timer and save its state."""
    # Record the start time and duration
    start_time = time.time()
    timer_state = {
        "start_time": start_time,
        "duration": seconds
    }

    # Save the state to a file
    with TIMER_STATE_FILE.open("w") as f:
        json.dump(timer_state, f)

    print(f"Timer started for {seconds} seconds.")
    print("You can check the timer progress by running the script with --check.")

    script = (
            f"import time, os; time.sleep({seconds}); os.system('notify-send Time is up!')"
        )

    # Run the timer script as a background process
    subprocess.Popen(
        [sys.executable, "-c", script],
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


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

    args = parser.parse_args()

    if args.check:
        check_timer()
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
