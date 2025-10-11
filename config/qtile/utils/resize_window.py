from libqtile.lazy import lazy as clazy


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
def grow_left_floating_window(window, width: int = 0):
    """
    Grow the floating windows left
    """
    window.cmd_resize_floating(width, 0)
    x_loc, y_loc = window.cmd_get_position()
    window.cmd_set_position_floating(x_loc - width, y_loc)


@clazy.window.function
def grow_right_floating_window(window, width: int = 0):
    """
    Grow the floating windows right
    """
    window.cmd_resize_floating(width, 0)


@clazy.window.function
def grow_down_floating_window(window, height: int = 0):
    """
    Grow the floating windows down
    """
    window.cmd_resize_floating(0, height)


@clazy.window.function
def grow_up_floating_window(window, height: int = 0):
    """
    Grow the floating windows up
    """
    window.cmd_resize_floating(0, height)
    x_loc, y_loc = window.cmd_get_position()
    window.cmd_set_position_floating(x_loc, y_loc - height)
