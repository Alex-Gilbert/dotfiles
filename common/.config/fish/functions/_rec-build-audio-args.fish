function _rec-build-audio-args --description "Pick audio source and return ffmpeg args"
    set -l src (rec-pick-audio)
    if test -n "$src"
        printf '%s\n' -f pulse -i $src -af "pan=stereo|c0=c0|c1=c0" -c:a aac -b:a 192k
    end
end
