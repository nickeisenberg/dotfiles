"""LaTeX math support for rich's Markdown renderer.

Math is parsed with mdit-py-plugins (`$...$`, `$$...$$`, `\\begin{align}`)
and converted to Unicode with pylatexenc. pylatexenc drops the braces of
super/subscripts and fractions, so those are handled here first.
"""

import re

from markdown_it import MarkdownIt
from mdit_py_plugins.amsmath import amsmath_plugin
from mdit_py_plugins.dollarmath import dollarmath_plugin
from pylatexenc.latex2text import (
    LatexNodes2Text,
    MacroTextSpec,
    get_default_latex_context_db,
)
from rich.markdown import Markdown, MarkdownElement
from rich.text import Text

# Pandoc's rules, so prices like "$5 and $10" don't become math.
parser = (
    MarkdownIt()
    .enable("strikethrough")
    .enable("table")
    .use(dollarmath_plugin, allow_space=False, allow_digits=False)
    .use(amsmath_plugin)
)

SUP = dict(
    zip(
        "0123456789+-−=()abcdefghijklmnoprstuvwxyzABDEGHIJKLMNOPRTUVWαβγδφχθ′",
        "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁻⁼⁽⁾ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻᴬᴮᴰᴱᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᴿᵀᵁⱽᵂᵅᵝᵞᵟᵠᵡᶿ′",
    )
)
SUB = dict(
    zip(
        "0123456789+-−=()aehijklmnoprstuvxβγρφχ",
        "₀₁₂₃₄₅₆₇₈₉₊₋₋₌₍₎ₐₑₕᵢⱼₖₗₘₙₒₚᵣₛₜᵤᵥₓᵦᵧᵨᵩᵪ",
    )
)


SUP["'"] = "′"

# pylatexenc drops the space after macros like \leq; relations get it back.
RELATIONS = re.compile(r"\s*([≤≥≠≈≡∼≃≅∝≪≫→←↔⇒⇐⇔↦∈∉∋⊂⊃⊆⊇])\s*")


def _frac(node, l2tobj):
    def part(arg):
        s = l2tobj.nodelist_to_text([arg]).strip()
        return s if len(s) == 1 or s.isalnum() else f"({s})"

    num, den = node.nodeargd.argnlist[-2:]
    return f"{part(num)}/{part(den)}"


_db = get_default_latex_context_db()
_db.add_context_category(
    "mark-tui",
    macros=[MacroTextSpec(m, simplify_repl=_frac) for m in ("frac", "dfrac", "tfrac")],
    prepend=True,
)
_l2t = LatexNodes2Text(latex_context=_db, math_mode="text")


def _script_arg(s, i):
    """Return (argument, end) of the ^/_ argument starting at s[i]."""
    while i < len(s) and s[i] == " ":
        i += 1
    if i >= len(s):
        return "", i
    if s[i] == "{":
        depth, j = 0, i
        while j < len(s):
            if s[j] == "{":
                depth += 1
            elif s[j] == "}":
                depth -= 1
                if depth == 0:
                    return s[i + 1 : j], j + 1
            elif s[j] == "\\":
                j += 1
            j += 1
        return s[i + 1 :], len(s)
    if s[i] == "\\":
        j = i + 1
        while j < len(s) and s[j].isalpha():
            j += 1
        return s[i : max(j, i + 2)], max(j, i + 2)
    return s[i], i + 1


def _scripts(s):
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\":
            out.append(s[i : i + 2])
            i += 2
        elif c in "^_":
            arg, i = _script_arg(s, i + 1)
            text = latex_to_unicode(arg).replace(" ", "")
            table = SUP if c == "^" else SUB
            if text and all(ch in table for ch in text):
                text = "".join(table[ch] for ch in text)
            elif len(text) > 1:
                text = f"{c}({text})"
            else:
                text = c + text
            # Braces keep the result from gluing onto a preceding macro name.
            out.append("{" + text + "}")
        else:
            out.append(c)
            i += 1
    return "".join(out)


def latex_to_unicode(src):
    try:
        text = _l2t.latex_to_text(_scripts(src))
        return RELATIONS.sub(r" \1 ", text).strip()
    except Exception:
        return src.strip()


def _rows(src):
    """Convert block math to lines, aligning columns at `&`."""
    body = re.sub(r"\\(begin|end)\{[^}]*\}(\{[^}]*\})?", "", src)
    rows = [r for r in re.split(r"\\\\|\n", body) if r.strip()]
    cells = [[latex_to_unicode(c) for c in r.split("&")] for r in rows]
    ncols = max(len(r) for r in cells) if cells else 0
    widths = [
        max((len(r[i]) for r in cells if i < len(r)), default=0)
        for i in range(ncols)
    ]
    lines = []
    for r in cells:
        # Odd columns (left of `&`) are right-aligned, like amsmath.
        parts = [
            c.rjust(widths[i]) if i % 2 == 0 else c.ljust(widths[i])
            for i, c in enumerate(r)
        ]
        lines.append(" ".join(parts).rstrip() if len(r) > 1 else r[0])
    return lines


class MathBlock(MarkdownElement):
    new_line = True

    @classmethod
    def create(cls, markdown, token):
        return cls()

    def on_text(self, context, text):
        self.source = text.strip()

    def __rich_console__(self, console, options):
        yield Text(
            "\n".join(_rows(self.source)), style="markdown.latex", justify="center"
        )


class MathMarkdown(Markdown):
    elements = {
        **Markdown.elements,
        "math_block": MathBlock,
        "math_block_label": MathBlock,
        "amsmath": MathBlock,
    }
    inlines = Markdown.inlines | {"latex"}

    def __init__(self, markup, **kwargs):
        super().__init__(markup, **kwargs)
        self.parsed = parser.parse(markup)
        # Inline math reuses rich's self-closing inline style path.
        for token in self.parsed:
            for child in token.children or ():
                if child.type == "math_inline":
                    child.tag = "latex"
                    child.content = latex_to_unicode(child.content)
