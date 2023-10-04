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
