import my_utils.nvidia_widget as nv

nn = nv.NvidiaSensors2(
    sensors=[
        "utilization.gpu",
        "memory.used",
    ], 
    format="{utilization_gpu} {memory_used}"
)


nn.poll()

list(nn._get_sensors_data(nn.command))[0]

nn.formatted_per_gpu
nn.sensors_data


nn.format.format(**nn.sensors_data[0])

list(nn._get_sensors_data(nn.command))[0]
