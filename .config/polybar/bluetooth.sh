#!/bin/bash

# bluetooth.sh - Status script
if [ "$(systemctl is-active bluetooth)" = "active" ]; then
    if [ "$(bluetoothctl show | grep 'Powered: yes')" ]; then
        # Check if any devices are connected
        if [ "$(bluetoothctl devices Connected | wc -l)" -gt 0 ]; then
            echo "Connected"
        else
            echo "On"
        fi
    else
        echo "Off"
    fi
else
    echo "Disabled"
fi
