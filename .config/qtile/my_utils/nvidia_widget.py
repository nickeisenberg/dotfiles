import csv
import re
from subprocess import CalledProcessError
from libqtile.widget import base

class NvidiaSensors2(base.ThreadPoolText):
    """
    Displays arbitrary sensor data from Nvidia GPU(s).
    Not backwards-compatible with ``libqtile.widget.NvidiaSensors``.
    """

    # TODO: Try backwards compatibility? Might not be possible

    defaults = [
        (
            "format",
            "{utilization_gpu}% {temperature_gpu}°C",
            "Display string format applied to individual GPUs. Available "
            "options are as definedin the ``sensors`` kwarg, except dots (.) "
            "are replaced with underscores (_)."
        ),
        (
            "format_all",
            "{}",
            "Format string applied to the splatted list of results that are "
            "already formatted (individually) by ``format``. Shows only the first "
            "GPU by default - MUST CHANGE TO DISPLAY MULTIPLE GPUS!"
        ),
        (
            "format_alert",
            None,
            "Format string that replaces ``format`` if temperature above threshold."
        ),
        (
            "format_all_alert",
            None,
            "Format string that replaces ``format_all`` if temperature above threshold."
        ),
        (
            "threshold",
            70,
            "If the current temperature value is above, "
            "then change to foreground_alert colour",
        ),
        (
            "gpu_bus_id",
            "",
            "GPU's Bus ID, ex: ``01:00.0``. If leave empty will display all " "available GPU's",
        ),
        (
            "update_interval",
            2,
            "Update interval in seconds."
        ),
        (
            "sensors",
            ["utilization.gpu", "temperature.gpu"],
            "List of sensor names to query. Run 'nvidia-smi --help-query-gpu' for full list."
        ),
    ]

    def __init__(self, **config):
        base.ThreadPoolText.__init__(self, "", **config)
        self.add_defaults(NvidiaSensors2.defaults)
        self.foreground_normal = self.foreground

        # If format(_all)_alert is not defined, default to the non-alerting formats.
        if self.format_alert is None:
            self.format_alert = self.format
        if self.format_all_alert is None:
            self.format_all_alert = self.format_all

    def _get_sensors_data(self, command):
        return csv.reader(
            self.call_process(command, shell=True).strip().replace(" ", "").split("\n")
        )

    def _parse_format_string(self):
        return {sensor for sensor in re.findall("{(.+?)}", self.format_per_gpu)}

    def _temperature_alert_check(self, data):
        # Return false if 'threshold' is unset or the 'temperature.gpu' field is not queried
        if self.threshold is None or "temperature.gpu" not in self.sensors:
            return False

        # Return true if any of the core temps >= threshold
        for gpu in data:
            if gpu["temperature_gpu"].isnumeric() and int(gpu["temperature_gpu"]) > self.threshold:
                return True

        # Otherwise return false
        return False


    def poll(self):
        # Command to retrieve GPU info
        bus_id = f"-i {self.gpu_bus_id}" if self.gpu_bus_id else ""
        command = "nvidia-smi {} --query-gpu={} --format=csv,noheader".format(
            bus_id,
            ",".join(self.sensors)
        )

        try:
            result = self._get_sensors_data(command)

            # Replace dots with underscores to avoid conflict with str.format
            sensors_alt_names = [ name.replace(".", "_") for name in self.sensors ]
            sensors_data = [ dict(zip(sensors_alt_names, [val.replace("%", "").strip() for val in gpu])) for gpu in result ]   # List items represent individual GPUs. Dict items represent sensor name/value pairs.

            # If any GPU's core temp is above the threshold, set alert
            if self._temperature_alert_check(sensors_data):
                formatted_per_gpu = [self.format_alert.format(**gpu) for gpu in sensors_data]
                return self.format_all_alert.format(*formatted_per_gpu)
            else:
                formatted_per_gpu = [self.format.format(**gpu) for gpu in sensors_data]
                return self.format_all.format(*formatted_per_gpu)

        except CalledProcessError as ex:    # Invalid sensor name
            return ex.stdout
        except Exception as ex:
            return str(ex)
