import os
import subprocess

from libqtile import bar, widget, hook
from libqtile.layout.columns import Columns
from libqtile.layout.xmonad import MonadTall
from libqtile.layout.matrix import Matrix
from libqtile.layout.floating import Floating
from libqtile.config import Click, Drag, Group, Key, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
from utils import (
    NvidiaSensors2,
    grow_up_floating_window,
    grow_right_floating_window,
    grow_left_floating_window,
    grow_down_floating_window,
    go_to_group,
    go_to_group_and_move_window,
)
from colors.vague import Colors

mod0 = "mod1"  # alt
mod1 = "mod4"  # super

alacrity_terminal = subprocess.run(
    "which alacritty", shell=True, stdout=subprocess.PIPE
).stdout

if alacrity_terminal:
    terminal = "alacritty"
else:
    terminal = "gnome-terminal"

browser = "firefox"
# --------------------------------------------------
# color setup
# --------------------------------------------------
colors = Colors()

barcolor = colors.barcolor
widget_background = colors.widget_background
widget_text_color = colors.widget_text_color
widget_font = "ComicShannsMonoNerdFont"
widget_fontsize = 22
urgent = colors.urgent
muted_urgent = colors.muted_urgent
selected = colors.selected

# --------------------------------------------------
# Key Bindings
# --------------------------------------------------

keys = [
    Key(["control"], "h", lazy.layout.left(), desc="focus to left"),
    Key(["control"], "l", lazy.layout.right(), desc="focus to right"),
    Key(["control"], "j", lazy.layout.down(), desc="focus down"),
    Key(["control"], "k", lazy.layout.up(), desc="focus up"),
    Key([mod0, "control"], "h", lazy.layout.shuffle_left(), desc="Move window left"),
    Key([mod0, "control"], "l", lazy.layout.shuffle_right(), desc="Move window right"),
    Key([mod0, "control"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod0, "control"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod0, "shift"], "h", lazy.layout.grow_left(), desc="Grow window left"),
    Key([mod0, "shift"], "l", lazy.layout.grow_right(), desc="Grow window right"),
    Key([mod0, "shift"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod0, "shift"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod0], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key([mod0], "f", lazy.window.toggle_fullscreen()),
    Key([mod0], "t", lazy.window.toggle_floating()),
    Key(
        [mod0], "l", grow_right_floating_window(width=15), desc="grow floating to right"
    ),
    Key([mod0], "h", grow_left_floating_window(width=15), desc="grow floating to left"),
    Key([mod0], "k", grow_up_floating_window(height=15), desc="grow floating to up"),
    Key(
        [mod0], "j", grow_down_floating_window(height=15), desc="grow floating to down"
    ),
    Key([mod0, mod1], "h", grow_right_floating_window(width=-15)),
    Key([mod0, mod1], "l", grow_left_floating_window(width=-15)),
    Key([mod0, mod1], "j", grow_up_floating_window(height=-15)),
    Key([mod0, mod1], "k", grow_down_floating_window(height=-15)),
    Key([mod0], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod0], "b", lazy.spawn(browser), desc=f"Launch {browser}"),
    Key(
        [mod0],
        "h",
        lazy.spawn(f"{browser} --new-window https://chat.openai.com/"),
        desc="Launch ChatGPT",
    ),
    Key([mod0], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod0], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod0, "control"], "r", lazy.reload_config(), desc="Reload config"),
    Key(
        [mod0, "control"],
        "b",
        lazy.spawn(os.path.expanduser("~/.config/rofi/launcher.sh")),
        desc="Launch the Rofi file explorer",
    ),
    Key(
        [mod0, "control"],
        "q",
        lazy.spawn(os.path.expanduser("~/.config/rofi/powermenu.sh")),
        desc="Launch the Rofi file explorer",
    ),
    Key(
        [mod1, "shift"],
        "4",
        lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/screenshot")),
        desc="screenshot of selected area",
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%"),
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%"),
    ),
    Key([], "XF86AudioMute", lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")),
    Key(
        [],
        "XF86MonBrightnessUp",
        lazy.spawn(
            os.path.expanduser(
                "~/.config/qtile/scripts/screen-brightness --which primary --value 5"
            )
        ),
        desc="Raise screen brightness",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        lazy.spawn(
            os.path.expanduser(
                "~/.config/qtile/scripts/screen-brightness --which primary --value -5"
            )
        ),
        desc="Lower screen brightness",
    ),
    Key(
        [mod1],
        "XF86MonBrightnessUp",
        lazy.spawn(
            os.path.expanduser(
                "~/.config/qtile/scripts/screen-brightness --which dual --value .1"
            )
        ),
        desc="Raise Bright by 5%",
    ),
    Key(
        [mod1],
        "XF86MonBrightnessDown",
        lazy.spawn(
            os.path.expanduser(
                "~/.config/qtile/scripts/screen-brightness --which dual --value -.1"
            )
        ),
        desc="Lower Bright by 5",
    ),
    Key(
        [mod0],
        "XF86MonBrightnessUp",
        lazy.spawn("/home/nicholas/.config/qtile/scripts/keylight 1"),
        desc="Raise keylight brightness",
    ),
    Key(
        [mod0],
        "XF86MonBrightnessDown",
        lazy.spawn(os.path.expanduser("~/.config/qtile/scripts/keylight -1")),
        desc="Raise keylight brightness",
    ),
]

# --------------------------------------------------
# Groups
# --------------------------------------------------
maingroups = [
    Group(name="1", label="1", screen_affinity=0),
    Group(name="2", label="2", screen_affinity=0),
    Group(name="3", label="3", screen_affinity=0),
    Group(name="4", label="4", screen_affinity=0),
    Group(name="5", label="5", screen_affinity=0),
    Group(name="6", label="6", screen_affinity=0),
]

dualgroups = [
    Group(name="7", label="7", screen_affinity=1),
    Group(name="8", label="8", screen_affinity=1),
    Group(name="9", label="9", screen_affinity=1),
    Group(name="0", label="10", screen_affinity=1),
]

groups = maingroups + dualgroups

main_group_box = widget.GroupBox(
    font=widget_font,
    fontsize=widget_fontsize,
    highlight_method="default",
    visible_groups=["1", "2", "3", "4", "5", "6"],
    background=widget_background,
    active=selected,
    inactive=widget_text_color,
    rounded=True,
    this_current_screen_border=muted_urgent,
    this_screen_border=urgent,
    blockwidth=2,
    margin_y=4,
)

dual_group_box = widget.GroupBox(
    fontsize=20,
    highlight_method="default",
    visible_groups=["7", "8", "9", "0"],
    background=widget_background,
    active=selected,
    inactive=widget_text_color,
    rounded=True,
    this_current_screen_border=muted_urgent,
    this_screen_border=urgent,
    block_highlight_text_color=widget_text_color,
    blockwidth=2,
    margin_y=3,
)


for i in groups:
    keys.append(
        Key(
            [mod0],
            i.name,
            lazy.function(go_to_group(i.name, maingroups)),
            desc="Switch to group {}".format(i.name),
        )
    )
    keys.append(
        Key(
            [mod0, "control"],
            i.name,
            lazy.function(go_to_group_and_move_window(i.name, maingroups)),
            desc="Switch to & move focused window to group {}".format(i.name),
        )
    )


# Scratchpad has to be defined after the groups above to avoid issue with the
# name "scratchpad" being in the group during the for loop above where I am
# defining the hot keys to move screens to a new monitor.
groups.append(
    ScratchPad(
        "scratchpad",
        [
            DropDown(
                "sp1",
                terminal,
                opacity=0.8,
                x=0.1,
                y=0.1,
                width=0.8,
                height=0.8,
                on_focus_lost_hide=True,
            ),
            DropDown(
                "sp2",
                terminal,
                opacity=0.8,
                x=0.1,
                y=0.1,
                width=0.8,
                height=0.8,
                on_focus_lost_hide=True,
            ),
            DropDown(
                "sp3",
                terminal,
                opacity=0.8,
                x=0.1,
                y=0.1,
                width=0.8,
                height=0.8,
                on_focus_lost_hide=True,
            ),
        ],
    ),
)

# toggle visibiliy of scratch pads
keys += [
    Key([], "F10", lazy.group["scratchpad"].dropdown_toggle("sp1")),
    Key([], "F11", lazy.group["scratchpad"].dropdown_toggle("sp2")),
    Key([], "F12", lazy.group["scratchpad"].dropdown_toggle("sp3")),
]


# To get wm_class, etc info, run xprop in a terminal and click on the window
floating_layout_theme = {
    "border_width": 2,
    "border_focus": selected,
    "border_normal": widget_background,
    # "float_rules": [
    #     *layout.Floating.default_float_rules,
    #     Match(func=lambda w: w.name and w.name.startswith('Figure')),  #matplotlib
    # ]
}

floating_layout = Floating(**floating_layout_theme)

layout_theme = {
    "border_width": 2,
    "border_focus": selected,
    "border_normal": widget_background,
    "single_border_width": 3,
    "margin": 5,
}

layouts = [
    Columns(**layout_theme),
    MonadTall(**layout_theme),
    Matrix(**layout_theme),
    Floating(**layout_theme),
]

# --------------------------------------------------
# Drag floating layouts.
# --------------------------------------------------
mouse = [
    Drag(
        [mod0],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod0], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod0], "Button2", lazy.window.bring_to_front()),
]
# --------------------------------------------------

mybar_items = []

mybar_items += [
    widget.Sep(background=barcolor, padding=10, linewidth=0),
    widget.TextBox(
        font="FontAwesome",
        text="",
        foreground=widget_text_color,
        background=widget_background,
        padding=5,
        fontsize=24,
    ),
    widget.Sep(background=barcolor, padding=10, linewidth=0),
    widget.Clock(
        font=widget_font,
        fontsize=widget_fontsize,
        foreground=widget_text_color,
        background=widget_background,
        format="%A, %b %d %I:%M %p ",
    ),
    widget.Spacer(),
    main_group_box,
    widget.Sep(padding=20, foreground=barcolor),
    widget.CurrentLayoutIcon(
        foreground=widget_text_color, background=widget_background, padding=0, scale=0.5
    ),
    widget.CurrentLayout(
        font=widget_font,
        fontsize=widget_fontsize,
        foreground=widget_text_color,
        background=widget_background,
    ),
    widget.Spacer(),
    widget.TextBox(
        font=widget_font,
        text="VRAM:",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=widget_fontsize,
    ),
    NvidiaSensors2(
        font=widget_font,
        sensors=["memory.used"],
        format="{memory_used}",
        fontsize=widget_fontsize,
        padding=5,
        background=widget_background,
        foreground=widget_text_color,
    ),
    widget.TextBox(
        text="\u2502",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=20,
    ),
    widget.TextBox(
        font=widget_font,
        fontsize=widget_fontsize,
        text=" RAM:",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
    ),
    widget.Memory(
        font=widget_font,
        foreground=widget_text_color,
        background=widget_background,
        fontsize=widget_fontsize,
        format="{MemUsed:.0f} MiB",
    ),
    widget.TextBox(
        text="\u2502",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=20,
    ),
    widget.TextBox(
        text="Vol:",
        font=widget_font,
        fontsize=widget_fontsize,
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
    ),
    widget.PulseVolume(
        font=widget_font,
        fontsize=widget_fontsize,
        padding=5,
        background=widget_background,
        foreground=widget_text_color,
    ),
    widget.TextBox(
        text="\u2502",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=20,
    ),
    widget.TextBox(
        font=widget_font,
        fontsize=widget_fontsize,
        text=" WiFi:",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
    ),
    widget.Wlan(
        font=widget_font,
        fontsize=widget_fontsize,
        interface="wlp0s20f3",
        foreground=widget_text_color,
        background=widget_background,
        format="{essid} {percent:2.0%}",
    ),
    widget.TextBox(
        font="FontAwesome",
        text="\u2502",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=20,
    ),
    widget.Battery(
        font=widget_font,
        fontsize=widget_fontsize,
        battery="BAT0",
        foreground=widget_text_color,
        background=widget_background,
        low_percentage=0.2,
        low_foreground=widget_text_color,
        update_interval=1,
        format="{char} {percent:2.0%}",
        # charge_char="  ",
        # discharge_char="\uf0e7",
        charge_char="Bat: (C)",
        discharge_char="Bat: (NC)",
        not_charging_char="Bat: (NC)",
    ),
    widget.Sep(background=barcolor, padding=20, linewidth=0),
]

mybar_dual_items = [
    widget.Sep(background=barcolor, padding=10, linewidth=0),
    widget.Clock(
        foreground=widget_text_color,
        # background=background,
        background=widget_background,
        fontsize=20,
        format="%A, %b %d %I:%M %p ",
    ),
    widget.Spacer(),
    dual_group_box,
    widget.CurrentLayoutIcon(
        foreground=widget_text_color, background=widget_background, padding=0, scale=0.5
    ),
    widget.CurrentLayout(
        fontsize=20,
        foreground=widget_text_color,
        background=widget_background,
    ),
    widget.Spacer(),
]

mybar = bar.Bar(
    mybar_items,
    size=widget_fontsize * 2,
    background=barcolor,
    margin=[0, 0, 0, 0],
    border_width=[0, 0, 0, 0],
    border_color=barcolor,
)

mybar_dual = bar.Bar(
    mybar_dual_items,
    25,
    background=barcolor,
    margin=[0, 0, 0, 0],
    border_width=[8, 0, 8, 0],
    border_color=barcolor,
)

# wallpaper now set in autostart.sh
screens = [
    Screen(
        top=mybar,
    ),
    Screen(top=mybar_dual),
]

# --------------------------------------------------
# from qtile default
# --------------------------------------------------
dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

wmname = "qtile"


@hook.subscribe.startup_once
def autostart():
    subprocess.Popen("${HOME}/.config/qtile/scripts/autostart.sh", shell=True)
