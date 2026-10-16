"""python -m richmdviewnvim <socket> [--images]"""

from richmdviewnvim.viewer import main

try:
    main()
except KeyboardInterrupt:
    pass
