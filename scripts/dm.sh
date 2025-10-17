# A quick tool to refresh the screen when switching from dual monitor to non dual monitors.

function dm() {
    var=$(xrandr | awk '/HDMI-1-0/ {print $2}')

    if [ "$var" = "connected" ]; then
        xrandr --output HDMI-1-0 --auto
        xrandr --output HDMI-1-0 --noprimary --above eDP-1
    
    elif [ "$var" = "disconnected" ]; then
        xrandr --output HDMI-1-0 --off
    fi
    
    feh --no-fehbg --bg-scale ${HOME}/.config/qtile/assets/house-on-river.jpg
}
