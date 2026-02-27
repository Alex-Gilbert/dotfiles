function rec-crop --description "Record a selected region of the screen"
    set -l name $argv[1]
    if test -z "$name"
        set name rec-(date +%Y%m%d-%H%M%S)
    end

    set -l output ~/Videos/{$name}.mkv
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    set -l audio_src (rec-pick-audio)
    set -l audio_args
    if test -n "$audio_src"
        set audio_args -f pulse -i $audio_src -af "pan=stereo|c0=c0|c1=c0" -c:a aac -b:a 192k
    end

    set -l webcam (rec-pick-webcam)

    echo "Click and drag to select the recording area..."
    set -l geom (slop -f "%w %h %x %y")

    if test $status -ne 0
        echo "Selection cancelled"
        return 1
    end

    set -l w (echo $geom | awk '{print $1}')
    set -l h (echo $geom | awk '{print $2}')
    set -l x (echo $geom | awk '{print $3}')
    set -l y (echo $geom | awk '{print $4}')

    # Force even dimensions (ffmpeg requirement)
    set w (math "$w - ($w % 2)")
    set h (math "$h - ($h % 2)")

    # Start webcam recording in background
    set -l webcam_pid ""
    if test -n "$webcam"
        ffmpeg -nostdin -f v4l2 -input_format mjpeg -framerate 30 -video_size 1920x1080 -i $webcam \
            -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
            $webcam_output &
        set webcam_pid $last_pid
        echo "Webcam recording started (PID $webcam_pid)"
    end

    echo "Recording {$w}x{$h} at offset +{$x}+{$y}"
    echo "Press q to stop"

    ffmpeg -video_size {$w}x{$h} -framerate 60 -f x11grab -i :0.0+{$x},{$y} \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $output

    if test -n "$webcam_pid"
        kill -INT $webcam_pid 2>/dev/null
        wait $webcam_pid 2>/dev/null
        echo "Webcam saved: $webcam_output"
    end

    if test $status -eq 0
        echo "Saved: $output"
    end
end
