function rec-tiktok --description "Record a region and output 1080x1920 vertical video for TikTok"
    set -l name $argv[1]
    if test -z "$name"
        set name tiktok-(date +%Y%m%d-%H%M%S)
    end

    set -l raw ~/Videos/{$name}-raw.mkv
    set -l output ~/Videos/{$name}.mp4
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    set -l audio_args (_rec-build-audio-args)
    set -l webcam (rec-pick-webcam)

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

    set -l webcam_pid (_rec-webcam-start $webcam $webcam_output)

    echo "Recording {$w}x{$h} at offset +{$x}+{$y}"
    echo "Press q to stop"

    ffmpeg -video_size {$w}x{$h} -framerate 60 -f x11grab -i :0.0+{$x},{$y} \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $raw

    _rec-webcam-stop $webcam_pid $webcam_output

    if test $status -eq 0
        echo ""
        echo "Scaling to 1080x1920 ..."
        set -l audio_post_args
        if test (count $audio_args) -gt 0
            set audio_post_args -c:a copy
        end

        ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i $raw \
            -vf "scale_cuda=1080:1920:interp_algo=lanczos" \
            $audio_post_args \
            -c:v hevc_nvenc -preset p7 -cq 20 -b:v 0 \
            $output

        if test $status -eq 0
            echo "Done: $output"
            rm $raw
            echo "Removed $raw"
        end
    end

    _rec-convert-davinci $output
end
