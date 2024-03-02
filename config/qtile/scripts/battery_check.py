import subprocess
import time
import psutil

first = False
while not first:
    if psutil.sensors_battery().percent < 15:
        subprocess.run([
            'notify-send', 
            'Low Battery', 
            'Your battery below 15%.'
        ])
        first = True
    time.sleep(60)

second = False
while not second:
    if psutil.sensors_battery().percent < 5:
        subprocess.run([
            'notify-send', 
            'Low Battery', 
            'Your battery below 5%.'
        ])
        second= True
    time.sleep(60)
