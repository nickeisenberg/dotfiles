import numpy as np
from libqtile.config import Group


def go_to_group(name: str, maingroups:list[Group]):
    """
    See "How can I get my groups to stick to screens?" on the following link
    https://docs.qtile.org/en/latest/manual/faq.html
    """
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


def go_to_group_and_move_window(name: str, maingroups:list[Group]):
    """
    See "How can I get my groups to stick to screens?" on the following link
    https://docs.qtile.org/en/latest/manual/faq.html
    """
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
