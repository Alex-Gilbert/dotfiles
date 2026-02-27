function rec-pick-audio --description "Pick a PulseAudio/PipeWire source for recording"
    set -l source (pactl list short sources | awk '{print $2}' | fzf --prompt="Audio source (ESC for none): " --height=~20)

    if test -z "$source"
        return 1
    end

    echo $source
end
