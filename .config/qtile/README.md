### Battery Widget
* There was no battery status icon for "Not charging". There were several changes
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
  * Second, I had to to add to the `update_status' method of `class _LinuxBattery`:
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
Inside of `libqtile.widget.groupbox.py` under the `draw` method, I added
```
#----------
if self.bar.screen.group.name == g.name:
    if self.qtile.current_screen == self.bar.screen:
        text_color = self.this_current_screen_border
    else:
        text_color = self.this_screen_border
#----------
```
for `highlight_method="text"`.
