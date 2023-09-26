import os
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


mod = "mod1"
# terminal = guess_terminal()
terminal = 'alacritty'
browser = "firefox"



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
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    Key([mod], "l", grow_right_floating_window(width=15), desc='grow floating to right'),
    Key([mod], "h", grow_left_floating_window(width=15), desc='grow floating to left'), 
    Key([mod], "k", grow_up_floating_window(height=15), desc='grow floating to up'), 
    Key([mod], "j", grow_down_floating_window(height=15), desc='grow floating to down'),
    Key(
        [mod, "mod4"], "h", grow_right_floating_window(width=-15), 
        desc='shrink floating to right'
    ),
    Key(
        [mod, "mod4"], "l", grow_left_floating_window(width=-15), 
        desc='shrink floating to left'
    ), 
    Key(
        [mod, "mod4"], "j", grow_up_floating_window(height=-15), 
        desc='shrink floating to up'
    ), 
    Key(
        [mod, "mod4"], "k", grow_down_floating_window(height=-15), 
        desc='shrink floating to down'
    ),
    
    # Fullscreen and floating
    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen on the focused window",),
    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    
    # Launch Apps
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "b", lazy.spawn(browser), desc=f"Launch {browser}"),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    
    # System
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    # Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),

    # Applications
    Key(
        [mod, "control"], "b", 
        lazy.spawn(
            os.path.expanduser("~/.config/rofi/scripts/launcher_t1")
        ), 
        desc="Launch the Rofi file explorer"
    ),

    Key(
        [mod, "control"], "q", 
        lazy.spawn(
            os.path.expanduser("~/.config/rofi/scripts/powermenu_t1")
        ), 
        desc="Launch the Rofi file explorer"
    ),

    # Screen shoot
    # Full screen
    Key(
        ["mod4", "shift"], "3", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/full_screenshot.sh")
            # "maim -u /home/nicholas/Pictures/Screenshot/screen_$(date +%Y-%m-%d-%T).png"
        )
    ),
    # Select area
    Key(
        ["mod4", "shift"], "4", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/selected_screenshot.sh")
        )
    ),
    # within active screen screen
    Key(
        ["mod4", "shift"], "5", 
        lazy.spawn(
            os.path.expanduser("~/.config/qtile/scripts/active_win_screenshot.sh")
        )
    ),
    Key([], "XF86AudioLowerVolume", 
        lazy.spawn("amixer -D pulse sset Master 5%-"), 
        desc="Lower Volume by 5%"
    ),
    Key([], "XF86AudioRaiseVolume", 
        lazy.spawn("amixer -D pulse sset Master 5%+"), 
        desc="Lower Volume by 5%"
    ),
    Key([], "XF86AudioMute", 
        lazy.spawn("amixer -q -D pulse sset Master toggle"), 
        desc="Lower Volume by 5%"
    ),
]




#--------------------------------------------------
# Groups
#--------------------------------------------------
groups = [Group(i) for i in "12345"]

for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [mod, "control"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
        ]
    )

#--------------------------------------------------
# Scratch pad and keybindings
#--------------------------------------------------
groups.append(
    ScratchPad(
        "6",
        [
            DropDown(
                "chatgpt", 
                f"{browser} --app=https://chat.openai.com", 
                x=0.3, y=0.1, 
                width=0.40, height=0.4, 
                on_focus_lost_hide=False
            ),
            DropDown(
               "mousepad", "mousepad", 
               x=0.3, y=0.1, 
               width=0.40, height=0.4, 
               on_focus_lost_hide=False),
            DropDown(
                "terminal", f"{terminal}", 
                x=0.3, y=0.1, 
                width=0.40, height=0.4, 
                on_focus_lost_hide=False
            ),
        ]
    )
)

keys.extend([
    Key([mod], 'F10', lazy.group["6"].dropdown_toggle("chatgpt")),
    Key([mod], 'F11', lazy.group["6"].dropdown_toggle("mousepad")),
    Key([mod], 'F12', lazy.group["6"].dropdown_toggle("terminal")),
])


#--------------------------------------------------
# Layouts
#--------------------------------------------------
floating_layout_theme = { 
    "border_width": 2,
    "border_focus": "#f6c177",
    "border_normal": "#FFFFFF",
    "float_rules": [
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ]
}

floating_layout = layout.Floating(**floating_layout_theme)

layout_theme = { 
    "border_width": 2,
    "border_focus": "#f6c177",
    "single_border_width": 3,
    "margin": 5
}

layouts = [
    layout.MonadTall(**layout_theme),
    layout.Matrix(**layout_theme),
    layout.Columns(**layout_theme),
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
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]


#--------------------------------------------------

colors =  [
        ["#1b1c26", "#14151C", "#1b1c26"], # color 0
        ["#485062", "#485062", "#485062"], # color 1
        ["#65bdd8", "#65bdd8", "#65bdd8"], # color 2
        ["#bc7cf7", "#a269cf", "#bc7cf7"], # color 3
        ["#aed1dc", "#98B7C0", "#aed1dc"], # color 4
        ["#ffffff", "#ffffff", "#ffffff"], # color 5
        ["#bb94cc", "#AB87BB", "#bb94cc"], # color 6
        ["#9859B3", "#8455A8", "#9859B3"], # color 7
        ["#744B94", "#694486", "#744B94"], # color 8
        ["#0ee9af", "#0ee9af", "#0ee9af"]] # color 9
   
# some rose pine colors
background = "#191724"
background_alt = "#2E2B46"
foreground = "#e0def4"
selected = "#31748f"
urgent = "#eb6f92"
active = "#9ccfd8"
widget_text_color = "#ffffff"


widget_defaults = dict(
    font='UbuntuMono Nerd Font',
    fontsize=16,
    padding=3,
)

extension_defaults = widget_defaults.copy()

mybar = []

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

mybar.append(
    widget.Clock(
        foreground=widget_text_color,
        background=background,
        fontsize=17,
        format='%A, %b %d | %I:%M %p',
    )
)


mybar.append(widget.Spacer()) 

mybar.append(
    widget.GroupBox(
        background=background,
        active=urgent,
        inactive=widget_text_color,
        rounded=True,
        highlight_color=colors[0],
        highlight_method="line",
        this_current_screen_border=colors[0],
        block_highlight_text_color=colors[2],
        blockwidth=2,
        margin_y=5,
    )
)

mybar.append(widget.Spacer())

mybar += [
    widget.CurrentLayoutIcon(
        # custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons")],
        foreground=widget_text_color,
        background=background,
        padding=0,
        scale=.5,
    ),
    widget.CurrentLayout(
        foreground=widget_text_color,
        background=background,
    )
]

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))


mybar += [
    widget.TextBox(
        font='FontAwesome',
         #text="",
        text="CPU",
        foreground=widget_text_color,
        background=background,
        padding=0,
        fontsize=16
    ),
    widget.CPU(
        foreground=widget_text_color,
        background=background,
        format='{load_percent}%',
    )
]

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

mybar += [
    widget.TextBox(
        font='FontAwesome',
        text="GPU",
        foreground=widget_text_color,
        background=background,
        padding=0,
        fontsize=16
    ),
    NvidiaSensors2(
        # sensors=["utilization.gpu"],
        # format="{utilization_gpu}%"
        sensors=["memory.used"],
        format="{memory_used}"
    )
]

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

mybar += [
    widget.TextBox(
        font='FontAwesome',
        # text="",
        text="RAM",
        foreground=widget_text_color,
        background=background,
        padding=0,
        fontsize=16
    ),
    widget.Memory(
        foreground=widget_text_color,
        background=background,
        fontsize=16,
        format='{MemUsed:.0f} MiB',
    )
]


mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

get_volume_cmd = 'amixer -D pulse get Master | awk -F \'Left:|[][]\' \'BEGIN {RS=\"\"}{ print $3 }\''
mybar += [
    widget.TextBox(
        font='FontAwesome',
        text="\uf028",
        foreground=widget_text_color,
        background=background,
        padding=0,
        fontsize=20
    ),
    widget.Volume(
        background=background,
        get_volume_command=get_volume_cmd
    )
]

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

mybar.append(
    widget.Battery(
        battery="BAT0",
        font='FontAwesome',
        foreground=widget_text_color,
        background=background,
        fontsize=14,
        low_percentage=0.2,
        low_foreground=colors[5],
        update_interval=1,
        format='{char} {percent:2.0%}',
        charge_char="",
        discharge_char='',
    )
)

mybar.append(widget.Sep(background=background, padding=20, linewidth=0))

screens = [
    Screen(
        wallpaper="~/Pictures/Wallpaper/red-sun.png",
        wallpaper_mode="stretch",
        top=bar.Bar(
            mybar,
            30,
            background=background,
            # background=colors[0],
            # background="#00000000",
            margin=[5, 8, 0, 8],
            border_width=[0, 0 ,0 ,0],
            border_color=colors[0],
            # opacity=0.8,
        ),
    ),
]

# from qtile_extras import widget
# from qtile_extras.widget.decorations import RectDecoration
# 
# 
# decor = {
#     "decorations": [
#         RectDecoration(colour="#600060", radius=10, filled=True, padding_y=5)
#     ],
#     "padding": 18,
# }
# 
# 
# screens = [
#     Screen(
#         top=bar.Bar(
#             [
#                 widget.Sep(
#                     # background=colors[8],
#                     padding=20,
#                     linewidth=0,
#                 ),
#                 widget.Clock(
#                     foreground=colors[5],
#                     background=colors[8],
#                     format='%d %b | %A',
#                     **decor
#                 ),
#                 widget.CurrentLayoutIcon(
#                     custom_icon_paths=[os.path.expanduser("~/.config/qtile/icons")],
#                     foreground=colors[5],
#                     background=colors[8],
#                     padding=0,
#                     scale=0.5,
#                 ),
#                 widget.CurrentLayout(
#                     foreground=colors[5],
#                     background=colors[8],
#                     **decor
#                 ),
#                 widget.GroupBox(**decor),
#                 widget.Clock(**decor),
#                 widget.QuickExit(**decor),
#             ],
#             30,
#             background="#00000000",
#         )
#     )
# ]



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

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"

@hook.subscribe.startup
def autostart():
    home = os.path.expanduser('~/.config/qtile/scripts/autostart.sh')
    subprocess.Popen([home])
