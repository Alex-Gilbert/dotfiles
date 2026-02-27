function webcam --description "Preview webcam feed in a window"
    set -l device (rec-pick-webcam)

    if test -z "$device"
        echo "No webcam selected"
        return 1
    end

    echo "Previewing $device (close window or press q to stop)"

    mpv --profile=low-latency --untimed \
        --demuxer-lavf-format=video4linux2 \
        --demuxer-lavf-o=input_format=mjpeg,video_size=1920x1080,framerate=30 \
        av://v4l2:$device 2>&1 | grep -v "VIDIOC_QBUF\|Bad file descriptor\|Some buffers\|Cannot seek\|force-seekable"
end
