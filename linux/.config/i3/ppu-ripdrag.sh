#!/bin/sh
# TEMP ppu.toys video — delete with the TEMP block in config
cd ~/dev/ppu-demos/toys/sunny-land/assets || exit 1
ripdrag -n -i -r -s 512 ./* &
sleep 0.8
i3-msg '[class="ripdrag"] floating enable, resize set 560 px 2070 px, move position 2600 px 45 px'
