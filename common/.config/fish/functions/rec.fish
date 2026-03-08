function rec --description "Record screen at native 4K with NVENC"
    set -l name $argv[1]
    if test -z "$name"
        set name rec-(date +%Y%m%d-%H%M%S)
    end

    set -l output ~/Videos/{$name}.mkv
    set -l webcam_output ~/Videos/{$name}-webcam.mkv

    set -l audio_args (_rec-build-audio-args)
    set -l webcam (rec-pick-webcam)
    set -l webcam_pid (_rec-webcam-start $webcam $webcam_output)

    echo "Recording to $output"
    echo "Press q to stop"

    ffmpeg -video_size 3840x2160 -framerate 60 -f x11grab -i :0.0 \
        $audio_args \
        -c:v h264_nvenc -preset p7 -cq 18 -b:v 0 \
        $output

    _rec-webcam-stop $webcam_pid $webcam_output
    _rec-convert-davinci $output
end
