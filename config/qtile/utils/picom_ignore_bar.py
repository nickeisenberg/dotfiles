from libqtile import hook
from libqtile.bar import Bar


@hook.subscribe.startup
def _(bars: list[Bar]):
    """
    Name the bars so that Picom can ignore then for rounded edges.
    See corner radius in picom.conf
    """
    for bar in bars:
        bar.window.window.set_property("QTILE_BAR", 1, "CARDINAL", 32)
