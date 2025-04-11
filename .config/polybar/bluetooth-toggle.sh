#!/bin/bash

# bluetooth-toggle.sh - Toggle script
if [ "$(bluetoothctl show | grep 'Powered: yes')" ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Bluetooth turned off"
else
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth turned on"
fi
