### Install
* Had to install qtile with 
`pip install --no-build-isolation git+https://github.com/qtile/qtile.git`

### Battery Widget
* There was no battery status icon for "Not charging". So inside
`libqtile.widgets.battery` I added `NOTCHARGING` to `BatteryState`. 

I also had to add 
```
elif state == "Not charging":
    state = BatteryState.NOTCHARGING
```
inside of `libqtile.widgets.battery._LinuxBattery`. 

Lastly, I added
```
elif status.state == BatteryState.NOTCHARGING:
            char = self.discharge_char
```
inside of `libqtile.widgets.battery.Battery`.

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
