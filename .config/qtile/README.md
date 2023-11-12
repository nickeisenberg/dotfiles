### Battery Widget
There was no battery status icon for "Not charging". There were several changes
that I needed to make to take care of this inside 
`/home/nicholas/.local/lib/python3.10/site-packages/libqtile/widget/battery.py`

* First, I added `NOTCHARGING` to `class BatteryState`:
  ```
  @unique
  class BatteryState(Enum):
      CHARGING = 1
      DISCHARGING = 2
      FULL = 3
      EMPTY = 4
      UNKNOWN = 5
      NOTCHARGING = 6
  ```
* Second, I had to to add to the `update_status` method of `class _LinuxBattery`:
  ```
  elif state == "Not charging":
      state = BatteryState.NOTCHARGING
  ```
* Third, I had to the `build_string` method of `class Battery`: 
  ```
  elif status.state == BatteryState.NOTCHARGING:
      char = self.charge_char
  ```

### Text color on focued and unfocued screens
I wanted the text color of the group box widget to change when focusing on different
monitors. This feature was not set up, only the highlight color of the screen labels in
the group box widget could change. I wanted to change this so that I could set `•` as the
groupbox labels, and then if I chaged focus to my dual monitor, then the label would also
change color to let me know what monitor is currently focused. I did this for
`highlight_method='text'` of the `GroupBox` widget.

To do this, I needed to edit
`/home/nicholas/.local/lib/python3.10/site-packages/libqtile/widget/groupbox.py`.
Inside the `draw` method of `class GroupBox` I had to update the `if g.screen` statement.
Inside this `if` statement, there is the following if statement:
```
if self.highlight_method == "text":
    border = None
    text_color = self.this_current_screen_border
```
and I appended this `if` statement to include the following:
```
if g.screen:
    if self.highlight_method == "text":
        border = None
        text_color = self.this_current_screen_border
        #----------
        if self.bar.screen.group.name == g.name:
            if self.qtile.current_screen == self.bar.screen:
                text_color = self.this_current_screen_border
            else:
                text_color = self.this_screen_border
        #----------
```
