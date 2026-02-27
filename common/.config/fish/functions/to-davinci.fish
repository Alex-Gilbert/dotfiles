function to-davinci --description "Convert video to DNxHR MOV for DaVinci Resolve"
    set -l input $argv[1]
    if test -z "$input"
        echo "Usage: to-davinci <input> [output]"
        return 1
    end

    set -l output $argv[2]
    if test -z "$output"
        set -l base (string replace -r '\.[^.]+$' '' $input)
        set output {$base}-davinci.mov
    end

    echo "Converting $input → $output (DNxHR HQ)"

    ffmpeg -i $input \
        -vf "format=yuv422p" \
        -c:v dnxhd -profile:v dnxhr_hq \
        -c:a pcm_s16le \
        $output

    if test $status -eq 0
        echo "Done: $output"
    end
end
