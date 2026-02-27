function rec-pick-webcam --description "Pick a webcam device"
    set -l device (v4l2-ctl --list-devices 2>/dev/null | grep -A1 "" | grep "/dev/video" | string trim | fzf --prompt="Webcam (ESC for none): " --height=~10)

    if test -z "$device"
        return 1
    end

    echo $device
end
