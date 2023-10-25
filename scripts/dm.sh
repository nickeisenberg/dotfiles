# A quick tool to refresh the screen when switching from dual monitor to non dual monitors.

function dm() {
    xrandr --output HDMI-1-0 --off
    xrandr --output HDMI-1-0 --auto
    xrandr --output HDMI-1-0 --noprimary --above eDP-1
}
