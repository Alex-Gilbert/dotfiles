function rec-audio --description "Record audio from a selected source"
    set -l name $argv[1]
    if test -z "$name"
        set name audio-(date +%Y%m%d-%H%M%S)
    end

    set -l output ~/Videos/{$name}.flac

    set -l audio_src (rec-pick-audio)
    if test -z "$audio_src"
        echo "No audio source selected"
        return 1
    end

    echo "Recording to $output"
    echo "Press q to stop"

    ffmpeg -f pulse -i $audio_src \
        -af "pan=stereo|c0=c0|c1=c0" \
        $output
end
