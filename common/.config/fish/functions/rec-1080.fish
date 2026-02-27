function rec-1080 --description "Record screen and auto-downscale to 1080p DNxHR for DaVinci"
    set -l name $argv[1]
    if test -z "$name"
        set name rec-(date +%Y%m%d-%H%M%S)
    end

    set -l raw ~/Videos/{$name}-raw.mkv
    set -l output ~/Videos/{$name}.mov
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    set -l audio_src (rec-pick-audio)
    set -l audio_args
    if test -n "$audio_src"
        set audio_args -f pulse -i $audio_src -af "pan=stereo|c0=c0|c1=c0" -c:a aac -b:a 192k
    end

    set -l webcam (rec-pick-webcam)

    # Start webcam recording in background
    set -l webcam_pid ""
    if test -n "$webcam"
        ffmpeg -nostdin -f v4l2 -input_format mjpeg -framerate 30 -video_size 1920x1080 -i $webcam \
            -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
            $webcam_output &
        set webcam_pid $last_pid
        echo "Webcam recording started (PID $webcam_pid)"
    end

    echo "Recording to $raw"
    echo "Press q to stop, will auto-downscale to 1080p DNxHR"

    ffmpeg -video_size 3840x2160 -framerate 60 -f x11grab -i :0.0 \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $raw

    if test -n "$webcam_pid"
        kill -INT $webcam_pid 2>/dev/null
        wait $webcam_pid 2>/dev/null
        echo "Webcam saved: $webcam_output"
    end

    if test $status -eq 0
        echo ""
        echo "Downscaling to $output (DNxHR HQ) ..."
        ffmpeg -i $raw \
            -vf "scale=1920:1080:flags=lanczos" \
            -c:v dnxhd -profile:v dnxhr_hq \
            -c:a pcm_s16le \
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
