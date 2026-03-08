function _rec-webcam-start --description "Start background webcam recording, outputs PID"
    set -l device $argv[1]
    set -l output $argv[2]

    if test -z "$device"
        return 1
    end

    ffmpeg -nostdin -f v4l2 -input_format mjpeg -framerate 30 -video_size 1920x1080 -i $device \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $output &
    set -l pid $last_pid
    echo "Webcam recording started (PID $pid)" >&2
    echo $pid
end
