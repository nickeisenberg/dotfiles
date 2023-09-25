from libqtile.command import lazy as clazy

@clazy.window.function 
def resize_floating_window(window, width: int = 0, height: int = 0): 
    """
    Resize the floating windows
    """
    # window.cmd_set_size_floating(window.width + width, window.height + height)
    window.cmd_resize_floating(width, height)
    x_loc, y_loc = window.cmd_get_position()
    window.cmd_set_position_floating(x_loc - width, y_loc - height)

@clazy.window.function 
def grow_left_floating_window(window, width: int=0): 
    """
    Grow the floating windows left
    """
    window.cmd_resize_floating(width, 0)
    x_loc, y_loc = window.cmd_get_position()
    window.cmd_set_position_floating(x_loc - width, y_loc)

@clazy.window.function 
def grow_right_floating_window(window, width: int=0): 
    """
    Grow the floating windows right
    """
    window.cmd_resize_floating(width, 0)

@clazy.window.function 
def grow_down_floating_window(window, height: int=0): 
    """
    Grow the floating windows down
    """
    window.cmd_resize_floating(0, height)

@clazy.window.function 
def grow_up_floating_window(window, height: int=0): 
    """
    Grow the floating windows up
    """
    window.cmd_resize_floating(0, height)
    x_loc, y_loc = window.cmd_get_position()
    window.cmd_set_position_floating(x_loc, y_loc - height)

def make_pill(
    widget_types: list,
    background: str,
):
    """
    Will wrap a widget in a pill shaped icon. Does not work the best at the
    moment
    """
    pill = [
        widget.Sep(
        background=background,
        padding=5,
        linewidth=0,
        ),
        widget.TextBox(
            text="\uE0B6",
            foreground=background,
            # background="#00000000",
            background=background,
            padding=0,
            fontsize=35,
        ),
        *widget_types
        ,
        widget.TextBox(
            text="\ue0b4",
            foreground=background,
            # background="#00000000",
            background=background,
            padding=0,
            fontsize=45
        ),
        widget.Sep(
            # background="#00000000",
            background=colors[0],
            padding=5,
            linewidth=0,
        )
    ]
    return pill
