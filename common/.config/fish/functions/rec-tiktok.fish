function rec-tiktok --description "Record a region and output 1080x1920 vertical video for TikTok"
    set -l name $argv[1]
    if test -z "$name"
        set name tiktok-(date +%Y%m%d-%H%M%S)
    end

    set -l audio_src (rec-pick-audio)
    set -l audio_args
    set -l audio_rec_args
    if test -n "$audio_src"
        set audio_args -f pulse -i $audio_src -af "pan=stereo|c0=c0|c1=c0" -c:a aac -b:a 192k
        set audio_rec_args -c:a copy
    end

    set -l webcam (rec-pick-webcam)
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    echo "Click and drag to select the recording area (width sets the 9:16 region)..."
    set -l geom (slop -f "%w %h %x %y")

    if test $status -ne 0
        echo "Selection cancelled"
        return 1
    end

    set -l w (echo $geom | awk '{print $1}')
    set -l h (echo $geom | awk '{print $2}')
    set -l x (echo $geom | awk '{print $3}')
    set -l y (echo $geom | awk '{print $4}')

    # Get screen bounds
    set -l screen_w (xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f1)
    set -l screen_h (xdpyinfo | grep dimensions | awk '{print $2}' | cut -dx -f2)

    # Snap to 9:16 — try width first, fall back to height if it won't fit
    set -l target_h (math "round($w * 16 / 9)")

    if test (math "$y + $target_h") -le $screen_h
        set h $target_h
    else
        set h (math "$screen_h - $y")
        set w (math "round($h * 9 / 16)")
    end

    # Force even dimensions
    set w (math "$w - ($w % 2)")
    set h (math "$h - ($h % 2)")

    set -l raw ~/Videos/{$name}-raw.mkv
    set -l output ~/Videos/{$name}.mp4

    echo "Recording {$w}x{$h} at offset +{$x}+{$y}"

    # Start webcam recording in background
    set -l webcam_pid ""
    if test -n "$webcam"
        ffmpeg -nostdin -f v4l2 -input_format mjpeg -framerate 30 -video_size 1920x1080 -i $webcam \
            -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
            $webcam_output &
        set webcam_pid $last_pid
        echo "Webcam recording started (PID $webcam_pid)"
    end

    echo "Press q to stop"

    ffmpeg -video_size {$w}x{$h} -framerate 60 -f x11grab -i :0.0+{$x},{$y} \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $raw

    # Stop webcam when screen recording ends
    if test -n "$webcam_pid"
        kill -INT $webcam_pid 2>/dev/null
        wait $webcam_pid 2>/dev/null
        echo "Webcam saved: $webcam_output"
    end

    if test $status -eq 0
        echo ""
        echo "Scaling to 1080x1920 ..."
        ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $raw \
            -vf "scale_cuda=1080:1920:interp_algo=lanczos" \
            $audio_rec_args \
            -c:v hevc_nvenc -preset p7 -cq 20 -b:v 0 \
            $output

        if test $status -eq 0
            echo "Done: $output"
            echo "Remove raw? (y/n)"
            read -l confirm
            if test "$confirm" = y
                rm $raw
                echo "Removed $raw"
            end
        end
    end
end
