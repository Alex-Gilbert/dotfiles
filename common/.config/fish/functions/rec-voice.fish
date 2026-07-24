function rec-voice --description "Record a mono WAV voice reference for Chatterbox (cook-video narrator)"
    # Optional arg: output path. Defaults to the cook-video narrator reference.
    set -l output $argv[1]
    if test -z "$output"
        set output ~/dev/cook-video/voice/narrator.wav
    end

    set -l audio_src (rec-pick-audio)
    if test -z "$audio_src"
        echo "No audio source selected"
        return 1
    end

    mkdir -p (dirname $output)

    echo "Recording mono WAV → $output"
    echo "Aim for 10–15s in your target narrator voice. Press q to stop."

    # True mono (-ac 1), 24 kHz (-ar 24000, Chatterbox's native SR), 16-bit PCM.
    # No fake-stereo pan: a voice-clone reference wants a single clean channel.
    ffmpeg -f pulse -i $audio_src -ac 1 -ar 24000 -c:a pcm_s16le $output
end
