from pynvml import (
    nvmlInit,
    nvmlDeviceGetHandleByIndex,
    nvmlDeviceGetMemoryInfo,
    nvmlShutdown,
)

nvmlInit()

handle = nvmlDeviceGetHandleByIndex(0)
info = nvmlDeviceGetMemoryInfo(handle)

def to_gib(x):
    return x / 1024**2

total = to_gib(info.total)
used = to_gib(info.used)
free = to_gib(info.free)

nvmlShutdown()
