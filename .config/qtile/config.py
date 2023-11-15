import os
import numpy as np
import subprocess
from libqtile import bar, layout, widget, hook, qtile
from libqtile.config import (
    Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
)
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.command import lazy as clazy

from my_utils.utils import *
from my_utils.nvidia_widget import NvidiaSensors2

from libqtile.widget import battery


mod0 = "mod1"
mod1 = "mod4"

# terminal = guess_terminal()
terminal = 'alacritty'
browser = "firefox"


color = {
    "background": '#1a1b26',
    "background_alt": "#2E2B46",
    "fg_gutter": "#3b4261",
    "foreground": '#c0caf5',
    "black": '#1d202f',
    "red": '#f7768e',
    "red1": "#db4b4b",
    "green": '#9ece6a',
    "yellow": '#e0af68',
    "dark3": '#545c7e',
    "blue": '#7aa2f7',
    "blue1": "#2ac3de",
    "blue2": "#0db9d7",
    "blue5": "#89ddff",
    "blue6": "#b4f9f8",
    "blue7": "#394b70",
    "magenta": '#bb9af7',
    "cyan": '#7dcfff',
    "white": '#a9b1d6',
    "brightwhite": "#c0caf5"
}

barcolor = color["background"]

# widget_background = color["background_alt"]
# widget_text_color = color["brightwhite"]

widget_background = color["fg_gutter"]
widget_text_color = color["brightwhite"]

urgent = color["red"]
selected = color["blue"]

lp_path = "~/Dotfiles/.config/qtile/icons/lp_gutter.png"
rp_path = "~/Dotfiles/.config/qtile/icons/rp_gutter.png"


#--------------------------------------------------qtile window cmd_set_size_floating
# Ketbindings 
#--------------------------------------------------
# A list of available commands that can be bound to keys can be found
# at https://docs.qtile.org/en/latest/manual/config/lazy.html


keys = [
    # Switch between windows
    Key(['control'], "h", lazy.layout.left(), desc="Move focus to left"),
    Key(['control'], "l", lazy.layout.right(), desc="Move focus to right"),
    Key(['control'], "j", lazy.layout.down(), desc="Move focus down"),
    Key(['control'], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod0], "space", lazy.layout.next(), desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod0, "control"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod0, "control"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod0, "control"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod0, "control"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod0, "shift"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod0, "shift"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod0, "shift"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod0, "shift"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod0], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    Key([mod0], "l", grow_right_floating_window(width=15), desc='grow floating to right'),
    Key([mod0], "h", grow_left_floating_window(width=15), desc='grow floating to left'), 
    Key([mod0], "k", grow_up_floating_window(height=15), desc='grow floating to up'), 
    Key([mod0], "j", grow_down_floating_window(height=15), desc='grow floating to down'),
    Key(
        [mod0, mod1], "h", grow_right_floating_window(width=-15), 
        desc='shrink floating to right'
    ),
    Key(
        [mod0, mod1], "l", grow_left_floating_window(width=-15), 
        desc='shrink floating to left'
    ), 
    Key(
        [mod0, mod1], "j", grow_up_floating_window(height=-15), 
        desc='shrink floating to up'
    ), 
    Key(
        [mod0, mod1], "k", grow_down_floating_window(height=-15), 
        desc='shrink floating to down'
    ),
    
    # Fullscreen and floating
    Key([mod0], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window",),
    Key([mod0], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    
    # Launch Apps
    Key([mod0], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod0], "b", lazy.spawn(browser), desc=f"Launch {browser}"),
    # Toggle between different layouts as defined below
    Key([mod0], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    
    # System
    Key([mod0], "q", lazy.window.kill(), desc="Kill focused window"),
    # Key([mod0, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod0, "control"], "r", lazy.reload_config(), desc="Reload the config"),

    # Applications
    Key(
        [mod0, "control"], "b", 
        lazy.spawn(
            os.path.expanduser("~/.config/rofi/scripts/launcher_t2")
        ), 
        desc="Launch the Rofi file explorer"
    ),

    Key(
        [mod0, "control"], "q", 
        lazy.spawn(
            os.path.expanduser("~/.config/rofi/scripts/powermenu_t1")
        ), 
        desc="Launch the Rofi file explorer"
    ),

    # Screen shoot
    # Full screen
    Key(
        [mod1, "shift"], "3", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/full_screenshot.sh")
        )
    ),
    # Select area
    Key(
        [mod1, "shift"], "4", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/selected_screenshot.sh")
        )
    ),
    # within active screen screen
    Key(
        [mod1, "shift"], "5", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/active_win_screenshot.sh")
        )
    ),
    Key([], "XF86AudioLowerVolume", lazy.widget["pulsevolume"].decrease_vol()),
    Key([], "XF86AudioRaiseVolume", lazy.widget["pulsevolume"].increase_vol()),
    Key([], "XF86AudioMute", lazy.widget["pulsevolume"].mute()),
    Key([], "XF86MonBrightnessUp", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/inc_brightness.sh")
        ), 
        desc="Raise Bright by 5%"
    ),
    Key([], "XF86MonBrightnessDown", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/dec_brightness.sh")
        ), 
        desc="Lower Bright by 5"
    ),
    Key([mod1], "XF86MonBrightnessUp", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/inc_dualbrightness.sh")
        ), 
        desc="Raise Bright by 5%"
    ),
    Key([mod1], "XF86MonBrightnessDown", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/dec_dualbrightness.sh")
        ), 
        desc="Lower Bright by 5"
    ),
    Key([mod0], "XF86MonBrightnessUp", 
        lazy.spawn(
            os.path.expanduser("sudo ~/.config/qtile/scripts/inc_keylight.sh"),
            shell=True   
        ), 
        desc="Raise Bright by 5%"
    ),
    Key([mod0], "XF86MonBrightnessDown", 
        lazy.spawn(
            os.path.expanduser("sudo ~/.config/qtile/scripts/dec_keylight.sh"),
            shell=True
        ), 
        desc="Lower Bright by 5"
    ),
]


#--------------------------------------------------
# Groups
#--------------------------------------------------
# label="•"
maingroups = [
    Group(name="1", label="•", screen_affinity=0),
    Group(name="2", label="•", screen_affinity=0),
    Group(name="3", label="•", screen_affinity=0),
    Group(name="4", label="•", screen_affinity=0),
    Group(name="5", label="•", screen_affinity=0),
    Group(name="6", label="•", screen_affinity=0),
]

dualgroups = [
    Group(name="9", label="•", screen_affinity=1),
    Group(name="0", label="•", screen_affinity=1),
]

groups = maingroups + dualgroups

main_group_box = widget.GroupBox(
    fontsize=80,
    highlight_method="text",
    visible_groups=['1', '2', '3', '4', '5', '6'],
    background=widget_background,
    active=color['blue'],
    inactive=widget_text_color,
    rounded=True,
    this_current_screen_border=color["red1"],
    this_screen_border=color["red"],
    blockwidth=2,
    margin_y=3,
)

dual_group_box = widget.GroupBox(
    fontsize=80,
    highlight_method="text",
    visible_groups=['9', '0'],
    background=widget_background,
    active=color['blue'],
    inactive=widget_text_color,
    rounded=True,
    this_current_screen_border=color["red1"],
    this_screen_border=color["red"],
    block_highlight_text_color=widget_text_color,
    blockwidth=2,
    margin_y=3,
)


#--------------------------------------------------
# These are some functions that will help with moving screens
# in a dual monitor set up.
# see "How can I get my groups to stick to screens?" on the following link
# https://docs.qtile.org/en/latest/manual/faq.html
#--------------------------------------------------
def go_to_group(name: str):
    def _inner(qtile):
        if len(qtile.screens) == 1:
            qtile.groups_map[name].cmd_toscreen()
            return

        if name in np.arange(1, len(maingroups) + 1).astype(str):
            qtile.focus_screen(0)
            qtile.groups_map[name].cmd_toscreen()
        else:
            qtile.focus_screen(1)
            qtile.groups_map[name].cmd_toscreen()

    return _inner


def go_to_group_and_move_window(name: str):
    def _inner(qtile):
        if len(qtile.screens) == 1:
            qtile.current_window.togroup(name, switch_group=True)
            return

        if name in np.arange(1, len(maingroups) + 1).astype(str):
            qtile.current_window.togroup(name, switch_group=False)
            qtile.focus_screen(0)
            qtile.groups_map[name].cmd_toscreen()
        else:
            qtile.current_window.togroup(name, switch_group=False)
            qtile.focus_screen(1)
            qtile.groups_map[name].cmd_toscreen()

    return _inner


for i in groups:
    keys.append(
        Key(
            [mod0],
            i.name,
            lazy.function(go_to_group(i.name)),
            desc="Switch to group {}".format(i.name),
        )
    )
    keys.append(
        Key(
            [mod0, "control"],
            i.name,
            lazy.function(go_to_group_and_move_window(i.name)),
            desc="Switch to & move focused window to group {}".format(i.name),
        )
    )


#--------------------------------------------------
# Scratchpad has to be defined after the groups above to avoid issue with the 
# name "scratchpad" being in the group during the for loop above where I am 
# defining the hot keys to move screens to a new monitor.

groups.append(
    ScratchPad(
        "scratchpad",
        [
            DropDown(
                "sp1", 
                "alacritty", 
                opacity=0.8,
                x=0.1, 
                y=0.1, 
                width=.8, 
                height=.8, 
                on_focus_lost_hide=True
            ),
            DropDown(
                "sp2", 
                "alacritty", 
                opacity=0.8,
                x=0.1, 
                y=0.1, 
                width=.8, 
                height=.8, 
                on_focus_lost_hide=True
            ),
            DropDown(
                "sp3", 
                "alacritty", 
                opacity=0.8,
                x=0.1, 
                y=0.1, 
                width=.8, 
                height=.8, 
                on_focus_lost_hide=True
            ),
        ]
    ),
)

# toggle visibiliy of above defined DropDown named "term"
keys += [
  # Key([], 'F11', lazy.group['scratchpad'].dropdown_toggle('sp1')),
  Key([], 'F10', lazy.group['scratchpad'].dropdown_toggle('sp1')),
  Key([], 'F11', lazy.group['scratchpad'].dropdown_toggle('sp2')),
  Key([], 'F12', lazy.group['scratchpad'].dropdown_toggle('sp3')),
]

#--------------------------------------------------

#--------------------------------------------------
# Layouts
#--------------------------------------------------

# To get wm_class, etc info, run xprop in a terminal and click on the window
floating_layout_theme = { 
    "border_width": 2,
    "border_focus": selected,
    "border_normal": widget_background,
    "float_rules": [
        *layout.Floating.default_float_rules,
        # Match(wm_class="confirmreset"),  # gitk
        # Match(wm_class="makebranch"),  # gitk
        # Match(wm_class="maketag"),  # gitk
        # Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(wm_class="eog"),  # pyaws.plotter
        Match(wm_class="EOG"),  # pyaws.plotter
        Match(func=lambda w: w.name and w.name.startswith('Figure')),  #matplotlib
        # Match(title="branchdialog"),  # gitk
        # Match(title="pinentry"),
    ]
}

floating_layout = layout.Floating(**floating_layout_theme)

layout_theme = { 
    "border_width": 2,
    "border_focus": selected,
    "border_normal": widget_background,
    "single_border_width": 3,
    "margin": 5
}

layouts = [
    layout.Columns(**layout_theme),
    layout.MonadTall(**layout_theme),
    layout.Matrix(**layout_theme),
    layout.Floating(**layout_theme),
    # layout.Max(**layout_theme),
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

#--------------------------------------------------
# Drag floating layouts.
#--------------------------------------------------
mouse = [
    Drag([mod0], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod0], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod0], "Button2", lazy.window.bring_to_front()),
]


#--------------------------------------------------


widget_defaults = dict(
    font='UbuntuMono Nerd Font',
    fontsize=16,
    padding=3,
)

extension_defaults = widget_defaults.copy()

# The dual monitor bars are essentially the same except for the groupbox.
# sharebar_l and sharedbar_r are the shared left and right parts. The groupbox
# in the middle is the only change 

mybar = []
mybardual = []
sharedbar_l = []
sharedbar_r = []

sharedbar_l.append(
    widget.Sep(background=barcolor, padding=20, linewidth=0)
)

sharedbar_l.append(widget.Image(filename=lp_path))
sharedbar_l.append(
    widget.Clock(
        foreground=widget_text_color,
        # background=background,
        background=widget_background,
        fontsize=20,
        format='%A, %b %d | %I:%M %p',
    )
)
sharedbar_l.append(widget.Image(filename=rp_path))

sharedbar_r.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_l.append(widget.Image(filename=lp_path))
sharedbar_l += [
    widget.TextBox(
        font='FontAwesome',
        # text="\uf028",
        text=" ",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=20
    ),
    widget.PulseVolume(
        fontsize=18,
        background=widget_background,
        foreground=widget_text_color,
    )
]
sharedbar_l.append(widget.Image(filename=rp_path))

sharedbar_l.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_l.append(widget.Image(filename=lp_path))
sharedbar_l.append(
    widget.Battery(
        battery="BAT0",
        font='FontAwesome',
        foreground=widget_text_color,
        background=widget_background,
        fontsize=16,
        low_percentage=0.2,
        low_foreground=widget_text_color,
        update_interval=1,
        format='{char} {percent:2.0%}',
        charge_char="",
        # discharge_char='',
        discharge_char="\uf0e7",
    )
)
sharedbar_l.append(widget.Image(filename=rp_path))

sharedbar_l.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_l.append(widget.Image(filename=lp_path))
sharedbar_l.append(
    widget.LaunchBar(
        fontsize=20,
        foreground=widget_text_color,
        background=widget_background,
        progs=[
            (' ', 'spotify', 'launch spotify'),
            (' ', 'thunderbird', 'launch mail'),
            (' ', 'alacritty -e nmtui', 'Network Manager')
        ]
    )
)
sharedbar_l.append(widget.Image(filename=rp_path))

sharedbar_l.append(widget.Spacer()) 

mybar.append(widget.Image(filename=lp_path))
mybar.append(main_group_box)
mybar.append(widget.Image(filename=rp_path))

mybardual.append(widget.Image(filename=lp_path))
mybardual.append(dual_group_box)
mybardual.append(widget.Image(filename=rp_path))

sharedbar_r.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_r.append(widget.Image(filename=lp_path))
sharedbar_r += [
    widget.CurrentLayoutIcon(
        # custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons")],
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        scale=.5
    ),
    widget.CurrentLayout(
        fontsize=20,
        foreground=widget_text_color,
        background=widget_background,
    )
]
sharedbar_r.append(widget.Image(filename=rp_path))

sharedbar_r.append(widget.Spacer())

sharedbar_r.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_r.append(widget.Image(filename=lp_path))
sharedbar_r += [
    widget.Net(
        format='{down:.0f}{down_suffix} ↓↑ {up:.0f}{up_suffix}',
        fontsize=20,
        background=widget_background,
        foreground=widget_text_color
    )
]
sharedbar_r.append(widget.Image(filename=rp_path))

sharedbar_r.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_r.append(widget.Image(filename=lp_path))
sharedbar_r += [
    widget.TextBox(
        font='FontAwesome',
        text="vRAM",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=16
    ),
    NvidiaSensors2(
        # sensors=["utilization.gpu"],
        # format="{utilization_gpu}%"
        sensors=["memory.used"],
        format="{memory_used}",
        fontsize=20,
        background=widget_background,
        foreground=widget_text_color
    )
]
sharedbar_r.append(widget.Image(filename=rp_path))

sharedbar_r.append(widget.Sep(background=barcolor, padding=0, linewidth=0))

sharedbar_r.append(widget.Image(filename=lp_path))
sharedbar_r += [
    widget.TextBox(
        font='FontAwesome',
        # text="",
        text="RAM ",
        foreground=widget_text_color,
        background=widget_background,
        padding=0,
        fontsize=16
    ),
    widget.Memory(
        foreground=widget_text_color,
        background=widget_background,
        fontsize=20,
        format='{MemUsed:.0f} MiB',
    )
]
sharedbar_r.append(widget.Image(filename=rp_path))


sharedbar_r.append(widget.Sep(background=barcolor, padding=20, linewidth=0))

mybar = sharedbar_l + mybar + sharedbar_r
mybardual = sharedbar_l + mybardual + sharedbar_r

mybar = bar.Bar(
    mybar,
    35,
    background=barcolor,
    # margin=[5, 8, 0, 8],
    margin=[0, 0, 0, 0],
    border_width=[8, 0, 8, 0],
    border_color=barcolor,
    # opacity=0.8,
) 

mybardual = bar.Bar(
    mybardual,
    35,
    background=barcolor,
    # margin=[5, 8, 0, 8],
    margin=[0, 0, 0, 0],
    border_width=[8, 0, 8, 0],
    border_color=barcolor,
    # opacity=0.8,
)

@hook.subscribe.startup
def _():
    """
    Name the bars so that Picom can ignore then for rounded edges.
    See corner radius in picom.conf
    """
    mybar.window.window.set_property("QTILE_BAR", 1, "CARDINAL", 32)
    mybardual.window.window.set_property("QTILE_BAR", 2, "CARDINAL", 32)

# peakpx.com for the wallpapers
# Use `xrandr --listmonitors` to see the correct order
screens = [
    Screen(
        # wallpaper="~/Pictures/Wallpaper/snow-mountain.jpg",
        wallpaper="~/Pictures/Wallpaper/fuji.jpg",
        wallpaper_mode="stretch",
        top=mybar
    ),
    Screen(
        # wallpaper="~/Pictures/Wallpaper/snow-mountain.jpg",
        wallpaper="~/Pictures/Wallpaper/fuji.jpg",
        wallpaper_mode="stretch",
        top=mybardual
    ),
]


#--------------------------------------------------
# general setup
#--------------------------------------------------
dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

wmname = "qtile"

@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
    subprocess.Popen([home])
