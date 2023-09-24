Some changes made...
* There was no battery status icon for "Not charging". So inside
`libqtile.widgets.battery` I added `NOTCHARGING` to `BatteryState`. I also had
to add 
```
elif state == "Not charging":
    state = BatteryState.NOTCHARGING
```
inside of `libqtile.widgets.battery._LinuxBattery`. Lastly, I added
```
elif status.state == BatteryState.NOTCHARGING:
            char = self.discharge_char
```
inside of `libqtile.widgets.battery.Battery`.