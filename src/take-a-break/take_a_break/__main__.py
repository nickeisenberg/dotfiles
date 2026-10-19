import json
import sys

from .cli import main

if len(sys.argv) == 3 and sys.argv[1] == "_serve":
    # Internal entry point used by `tab start` to launch the background process.
    from .daemon import serve
    from .timer import Settings

    serve(Settings(**json.loads(sys.argv[2])))
else:
    main()
