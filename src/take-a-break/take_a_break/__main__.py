import json
import sys

internal = sys.argv[1:2]

if internal == ["_serve"]:
    # Internal entry point used by `tab start` to launch the background process.
    from .daemon import serve
    from .timer import Settings

    serve(Settings(**json.loads(sys.argv[2])))
elif internal == ["_window"]:
    # Internal entry point for the timer window, launched by the daemon.
    from .window import run

    run()
else:
    from .cli import main

    main()
