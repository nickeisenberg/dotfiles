import numpy as np
from libqtile.core.manager import Qtile
from libqtile.config import Group


def debug_log(x, get="type"):
    with open("/home/nicholas/test.txt", "a") as f:
        if get == "type":
            f.write(str(type(x)))
        elif get == "val":
            f.write(x)
        f.write("\n")
    return None

def _group_toscreen(group) -> None:
    """
    Compatibility wrapper for Qtile's group.toscreen() API.

    Older versions of Qtile expose:
        group.cmd_toscreen()

    Newer versions expose:
        group.toscreen()
    """
    if hasattr(group, "toscreen"):
        group.toscreen()
    else:
        group.cmd_toscreen()


def go_to_group(name: str, maingroups: list[Group]):
    """
    See "How can I get my groups to stick to screens?" on the following link:
    https://docs.qtile.org/en/latest/manual/faq.html
    """

    def _inner(qtile: Qtile):
        group = qtile.groups_map[name]

        if len(qtile.screens) == 1:
            _group_toscreen(group)
            return

        if name in np.arange(1, len(maingroups) + 1).astype(str):
            qtile.focus_screen(0)
            _group_toscreen(group)
        else:
            qtile.focus_screen(1)
            _group_toscreen(group)

    return _inner


def go_to_group_and_move_window(name: str, maingroups: list[Group]):
    """
    See "How can I get my groups to stick to screens?" on the following link:
    https://docs.qtile.org/en/latest/manual/faq.html
    """

    def _inner(qtile: Qtile):
        group = qtile.groups_map[name]

        if len(qtile.screens) == 1:
            qtile.current_window.togroup(name, switch_group=True)
            return

        qtile.current_window.togroup(name, switch_group=False)

        if name in np.arange(1, len(maingroups) + 1).astype(str):
            qtile.focus_screen(0)
            _group_toscreen(group)
        else:
            qtile.focus_screen(1)
            _group_toscreen(group)

    return _inner
