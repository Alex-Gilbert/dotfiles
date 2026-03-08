function rec-window --description "Record a specific window (click to select)"
    set -l name $argv[1]
    if test -z "$name"
        set name rec-(date +%Y%m%d-%H%M%S)
    end

    set -l output ~/Videos/{$name}.mkv
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    set -l audio_args (_rec-build-audio-args)
    set -l webcam (rec-pick-webcam)

    echo "Click on the window you want to record..."
    set -l win_id (xdotool selectwindow)

    if test $status -ne 0
        echo "Selection cancelled"
        return 1
    end

    # Get window geometry
    set -l geom (xdotool getwindowgeometry --shell $win_id)
    set -l x (echo $geom | string match -r 'X=(\d+)' | tail -1)
    set -l y (echo $geom | string match -r 'Y=(\d+)' | tail -1)
    set -l w (echo $geom | string match -r 'WIDTH=(\d+)' | tail -1)
    set -l h (echo $geom | string match -r 'HEIGHT=(\d+)' | tail -1)

    # Force even dimensions (ffmpeg requirement)
    set w (math "$w - ($w % 2)")
    set h (math "$h - ($h % 2)")

    set -l webcam_pid (_rec-webcam-start $webcam $webcam_output)

    echo "Recording window {$w}x{$h} at +{$x}+{$y}"
    echo "Press q to stop"

    ffmpeg -video_size {$w}x{$h} -framerate 60 -f x11grab -i :0.0+{$x},{$y} \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $output

    _rec-webcam-stop $webcam_pid $webcam_output
    _rec-convert-davinci $output
end
