import nvidia_widget as nv

nn = nv.NvidiaSensors2(
    sensors=[
        "utilization.gpu", 
        "memory.used",
        "memory.free"
    ], 
    format="{utilization_gpu}% {memory_used} {memory_free}"
)

nn.poll()
