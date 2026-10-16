"""rich's Markdown, extended for rich-md-view.

Adds LaTeX math, parsed with mdit-py-plugins (`$...$`, `$$...$$`,
`\\begin{align}`) and converted by latex, and headings whose shape shows
their level. THEME holds the styles these elements use.
"""

from collections.abc import Iterator
from typing import Any

from markdown_it import MarkdownIt
from markdown_it.token import Token
from mdit_py_plugins.amsmath import amsmath_plugin
from mdit_py_plugins.dollarmath import dollarmath_plugin
from rich.console import Console, ConsoleOptions, RenderableType
from rich.markdown import Heading, Markdown, MarkdownContext, MarkdownElement
from rich.padding import Padding
from rich.text import Text, TextType
from rich.theme import Theme

from richmdviewnvim.latex import latex_to_unicode, math_lines

# Pandoc's rules, so prices like "$5 and $10" don't become math.
parser = (
    MarkdownIt()
    .enable("strikethrough")
    .enable("table")
    .use(dollarmath_plugin, allow_space=False, allow_digits=False)
    .use(amsmath_plugin)
)

THEME = Theme(
    {
        "markdown.latex": "italic magenta",
        # h1's border is the band color, drawn as half blocks around it.
        "markdown.h1": "bold bright_white on blue",
        "markdown.h1.border": "blue",
        "markdown.h2": "bold magenta",
        "markdown.h2.border": "magenta",
        "markdown.h3": "bold cyan",
        "markdown.h4": "bold yellow",
        "markdown.h5": "italic",
        "markdown.h6": "dim italic",
        "markdown.image": "dim italic",
    }
)


class MathBlock(MarkdownElement):
    new_line = True

    @classmethod
    def create(cls, markdown: Markdown, token: Token) -> "MathBlock":
        return cls()

    def on_text(self, context: MarkdownContext, text: TextType) -> None:
        self.source = str(text).strip()

    def __rich_console__(
        self, console: Console, options: ConsoleOptions
    ) -> Iterator[RenderableType]:
        yield Text(
            "\n".join(math_lines(self.source)),
            style="markdown.latex",
            justify="center",
        )


class BoldHeading(Heading):
    """A heading whose shape, not just its style, shows the level.

    h1 is a full-width band, h2 has a heavy rule under it, h3 and h4 get a
    marker; h5 and h6 keep rich's plain styled text. Colors come from the
    markdown.h<n> and markdown.h<n>.border theme styles.
    """

    MARKERS = {"h3": "▍ ", "h4": "› "}

    def __rich_console__(
        self, console: Console, options: ConsoleOptions
    ) -> Iterator[RenderableType]:
        width = options.max_width
        text = self.text.copy()
        if self.tag == "h1":
            # Half blocks pad the band without blank rows, which
            # Document trims from each block.
            edge = console.get_style("markdown.h1.border")
            yield Text("▄" * width, style=edge)
            yield Padding(text, (0, 1), style="markdown.h1", expand=True)
            yield Text("▀" * width, style=edge)
        elif self.tag == "h2":
            yield text
            yield Text("━" * width, style="markdown.h2.border")
        elif self.tag in self.MARKERS:
            yield Text.assemble(
                (self.MARKERS[self.tag], self.style_name), text
            )
        else:
            yield text


class MdViewMarkdown(Markdown):
    elements = {
        **Markdown.elements,
        "heading_open": BoldHeading,
        "math_block": MathBlock,
        "math_block_label": MathBlock,
        "amsmath": MathBlock,
    }
    inlines = Markdown.inlines | {"latex", "image"}

    def __init__(self, markup: str, **kwargs: Any) -> None:
        super().__init__(markup, **kwargs)
        self.parsed = parser.parse(markup)
        # Inline math reuses rich's self-closing inline style path.
        for token in self.parsed:
            for child in token.children or ():
                if child.type == "math_inline":
                    child.tag = "latex"
                    child.content = latex_to_unicode(child.content)
                elif child.type == "image":
                    # Images that aren't drawn become a camera and their alt
                    # text (or file name), in place. rich's own placeholder
                    # moves to the start of the paragraph, and links the path
                    # as written, which is relative to the markdown file.
                    src = str(child.attrs.get("src", ""))
                    alt = child.content or src.rstrip("/").rsplit("/", 1)[-1]
                    child.tag = "image"
                    child.content = f"📷 {alt}"
                    child.children = None
